// npm start                         builds and starts the whole stack, then waits until both tenants answer
// npm start -- <service> [...]      (re)starts only the named services, for example after npm run stop -- postgres
import { spawnSync } from 'node:child_process';
import http from 'node:http';

const services = process.argv.slice(2);
const { status, error } = spawnSync(
  'docker',
  ['compose', '-f', 'local/compose.yml', 'up', '-d', '--build', ...services],
  { stdio: 'inherit' },
);
if (error || status !== 0) {
  console.error('Could not start the stack. Is Docker running, and are ports 29999, 30000 and 30001 free?');
  process.exit(status || 1);
}

const ready = (host) =>
  new Promise((resolve) => {
    const req = http.get({ host: 'localhost', port: 29999, path: '/api/health', headers: { Host: host } }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('error', () => resolve(false));
  });

if (services.length) process.exit(0);

console.log('Waiting for the tenants...');
const deadline = Date.now() + 120_000;
for (const host of ['a.localhost', 'b.localhost']) {
  while (!(await ready(host))) {
    if (Date.now() > deadline) {
      console.error(`${host} did not become healthy. Check "npm run logs".`);
      process.exit(1);
    }
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }
}

console.log(`
Stack is up.
  Tenant a:   http://a.localhost:29999/api/items  (or: curl -H "Host: a.localhost" http://localhost:29999/api/items)
  Tenant b:   http://b.localhost:29999/api/items
  Grafana:    http://localhost:30000  (admin / admin)
  Prometheus: http://localhost:30001

Next: npm run load, npm run stop -- postgres, npm start -- postgres, npm run logs, npm stop`);
