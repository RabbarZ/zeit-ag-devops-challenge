// npm stop                         stops everything and deletes the volumes
// npm run stop -- <service> [...]  stops only the named services (postgres, redis, tenant-b, ...)
import { spawnSync } from 'node:child_process';

const services = process.argv.slice(2);
const args = services.length ? ['stop', ...services] : ['down', '-v'];
const { status, error } = spawnSync('docker', ['compose', '-f', 'local/compose.yml', ...args], { stdio: 'inherit' });
if (error || status !== 0) process.exit(status || 1);
if (services.length) console.log(`Stopped. Bring it back with: npm start -- ${services.join(' ')}`);
