import http from 'node:http';
import Redis from 'ioredis';
import { Pool } from 'pg';

const PORT = Number(process.env.PORT ?? 3000);
const TENANT_ID = process.env.TENANT_ID ?? 'local';
const VERSION = process.env.BUILD_VERSION ?? 'dev';
const SHA = process.env.BUILD_SHA ?? 'unknown';

const db = new Pool({ connectionString: process.env.DATABASE_URL, max: 5, connectionTimeoutMillis: 2000 });
const redis = new Redis(process.env.REDIS_URL ?? 'redis://localhost:6379/0');

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

interface Result {
  status: number;
  body: unknown;
}

const SCHEMA_SQL = `
  CREATE TABLE IF NOT EXISTS items (id serial PRIMARY KEY, name text NOT NULL);
  INSERT INTO items (name) SELECT 'Shift ' || g FROM generate_series(1, 20) g
    WHERE NOT EXISTS (SELECT 1 FROM items);
`;

async function health(): Promise<Result> {
  try {
    await db.query('SELECT 1');
    return { status: 200, body: { status: 'ok', database: 'up', version: VERSION, sha: SHA } };
  } catch {
    return { status: 503, body: { status: 'error', database: 'down' } };
  }
}

async function items(): Promise<Result> {
  const key = `${TENANT_ID}:items`;
  const cached = await redis.get(key);
  if (cached !== null) return { status: 200, body: JSON.parse(cached) };

  const { rows } = await db.query<{ id: number; name: string }>('SELECT id, name FROM items ORDER BY id');
  await redis.set(key, JSON.stringify(rows), 'EX', 30);
  return { status: 200, body: rows };
}

// Stand-in for the planning solver: most runs take 150-1050 ms, about 5% add 3 s.
async function solve(): Promise<Result> {
  const started = Date.now();
  const tailMs = Math.random() < 0.05 ? 3000 : 0;
  await sleep(150 + Math.random() * 900 + tailMs);
  return { status: 200, body: { status: 'solved', durationMs: Date.now() - started } };
}

async function slow(url: URL): Promise<Result> {
  const ms = Math.min(Number(url.searchParams.get('ms') ?? 1000), 10_000);
  await sleep(ms);
  return { status: 200, body: { sleptMs: ms } };
}

async function route(method: string | undefined, url: URL): Promise<Result> {
  if (method === 'GET' && url.pathname === '/api/health') return health();
  if (method === 'GET' && url.pathname === '/api/items') return items();
  if (method === 'POST' && url.pathname === '/api/solve') return solve();
  if (method === 'GET' && url.pathname === '/api/slow') return slow(url);
  return { status: 404, body: { error: 'not found' } };
}

const SLOW_REQUEST_MS = 1000;

const server = http.createServer(async (req, res) => {
  const started = Date.now();
  const url = new URL(req.url ?? '/', 'http://localhost');
  try {
    const { status, body } = await route(req.method, url);
    res.writeHead(status, { 'content-type': 'application/json' });
    res.end(JSON.stringify(body));
    const durationMs = Date.now() - started;
    if (durationMs > SLOW_REQUEST_MS) {
      console.warn(JSON.stringify({ msg: 'slow request', path: url.pathname, durationMs }));
    }
  } catch (error) {
    console.error(JSON.stringify({ msg: 'request failed', path: url.pathname, error: String(error) }));
    res.writeHead(500, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'internal error' }));
  }
});

async function prepareDatabase(attempts = 30): Promise<void> {
  for (let attempt = 1; ; attempt++) {
    try {
      await db.query(SCHEMA_SQL);
      return;
    } catch (error) {
      if (attempt >= attempts) throw error;
      await sleep(2000);
    }
  }
}

server.listen(PORT, () => {
  console.log(JSON.stringify({ msg: 'listening', port: PORT, tenant: TENANT_ID }));
});

prepareDatabase().catch(error => {
  console.error(JSON.stringify({ msg: 'database not ready', error: String(error) }));
});

process.once('SIGTERM', () => {
  server.close(() => process.exit(0));
});
