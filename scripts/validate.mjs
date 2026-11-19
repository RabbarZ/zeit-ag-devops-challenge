// Checks the compose file and the Terraform formatting and validity. No cloud access needed.
// Each check is skipped with a warning when its tool (docker, terraform) is not installed.
import { spawnSync } from 'node:child_process';
import { mkdirSync, readdirSync } from 'node:fs';
import path from 'node:path';

const installed = (cmd, args = ['version']) => spawnSync(cmd, args, { stdio: 'ignore' }).status === 0;

const run = (cmd, args, env) => {
  console.log(`$ ${cmd} ${args.join(' ')}`);
  const { status, error } = spawnSync(cmd, args, { stdio: 'inherit', env: { ...process.env, ...env } });
  if (error || status !== 0) {
    console.error(`Failed: ${cmd} ${args.join(' ')}`);
    process.exit(status || 1);
  }
};

if (installed('docker', ['compose', 'version'])) {
  run('docker', ['compose', '-f', 'local/compose.yml', 'config', '--quiet']);
} else {
  console.warn('docker compose not found, skipping the compose check.');
}

if (!installed('terraform')) {
  console.warn('terraform not found, skipping the Terraform checks (needs 1.11.4 or newer).');
  process.exit(0);
}

// One provider cache for all four environments, so each provider version is downloaded once.
const cache = path.resolve('.terraform-cache');
mkdirSync(cache, { recursive: true });
const env = { TF_PLUGIN_CACHE_DIR: cache, TF_IN_AUTOMATION: '1' };

run('terraform', ['fmt', '-check', '-recursive', 'infra'], env);
for (const name of readdirSync('infra/environments')) {
  const dir = path.join('infra', 'environments', name);
  run('terraform', [`-chdir=${dir}`, 'init', '-backend=false', '-input=false', '-lockfile=readonly'], env);
  run('terraform', [`-chdir=${dir}`, 'validate'], env);
}
console.log('All checks passed.');
