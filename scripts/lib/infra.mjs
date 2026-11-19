import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

export const environments = ['control', 'observability', 'staging', 'production'];

export function runInfra({ operation, args, root, env = process.env, run = spawnSync, log = console.log, error = console.error }) {
  const usage = 'Usage: npm run infra.plan|infra.verify -- [control|observability|staging|production|all ...] [--dry-run]';
  if (!['plan', 'verify'].includes(operation)) {
    error(`Only plan and verify are supported.\n${usage}`);
    return 1;
  }
  if (args.includes('--help')) {
    log(`${usage}\nplan prints a mocked Terraform plan for staging; verify validates and tests all four environments.\nBoth run locally without Azure credentials or a backend. Terraform 1.11.4+ is required.\nExit 0 means local checks passed; exit 1 means a check failed. Neither command checks live drift.\n--dry-run only prints the commands. No apply, destroy or saved plans are supported.`);
    return 0;
  }
  const dryRun = args.includes('--dry-run');
  const requested = args.filter((arg) => arg !== '--dry-run');
  if (requested.some((name) => name !== 'all' && !environments.includes(name))) {
    error(`Unknown environment or option. ${usage}`);
    return 1;
  }
  const selected = requested.length ? [...new Set(requested.flatMap((name) => name === 'all' ? environments : [name]))]
    : operation === 'plan' ? ['staging'] : environments;
  // Fixtures supply all inputs. Never use the caller's cloud credentials, input
  // variables or injected CLI flags for this fictional, mock-only assessment.
  const commandEnv = Object.fromEntries(Object.entries(env).filter(([name]) => !/^(ARM_|AZURE_|TF_VAR_|TF_CLI_ARGS(?:_|$))/i.test(name)));
  commandEnv.TF_INPUT = '0';
  commandEnv.TF_IN_AUTOMATION = '1';
  commandEnv.TF_WORKSPACE = 'default';
  commandEnv.TF_PLUGIN_CACHE_DIR = path.join(root, '.terraform-cache');

  if (!dryRun) mkdirSync(commandEnv.TF_PLUGIN_CACHE_DIR, { recursive: true });
  const invoke = (argv, environment) => {
    log(`$ terraform ${argv.join(' ')}`);
    if (dryRun) return 0;
    const result = run('terraform', argv, {
      cwd: root,
      stdio: 'inherit',
      env: { ...commandEnv, TF_DATA_DIR: path.join(root, 'infra', 'environments', environment, '.terraform', 'local-mocks') },
    });
    if (result.error || result.status === null) {
      error(result.error?.code === 'ENOENT' ? 'Terraform not found. Install Terraform 1.11.4 or newer.' : 'Terraform could not complete.');
      return 1;
    }
    return result.status;
  };

  if (invoke(['fmt', '-check', '-recursive', 'infra'], selected[0]) !== 0) return 1;
  log('Local mock providers and fixture state only. No Azure credentials or backend are used; this is not a live drift check.');
  const failed = [];
  for (const name of selected) {
    const chdir = `-chdir=infra/environments/${name}`;
    if (!dryRun) {
      const fixture = path.join(root, 'infra', 'environments', name, 'tests', 'local.tftest.hcl');
      try {
        const source = readFileSync(fixture, 'utf8');
        if (!/\brun\s+"local_plan"\s*\{[\s\S]*?\bcommand\s*=\s*plan\b/.test(source)
            || /\bcommand\s*=\s*"?apply\b/.test(source) || !/\bmock_provider\s+"azurerm"/.test(source)) {
          throw new Error('Expected a mock-provider local_plan test with command = plan, and no apply runs.');
        }
      } catch (cause) {
        error(`Cannot run local fixture for ${name}: ${cause.message}`);
        failed.push(name);
        continue;
      }
    }
    const init = [chdir, 'init', '-backend=false', '-input=false', '-lockfile=readonly', '-no-color'];
    if (invoke(init, name) !== 0 || invoke([chdir, 'validate', '-no-color'], name) !== 0) {
      failed.push(name);
      continue;
    }
    // Terraform's plan-only tests support mock providers and overridden remote
    // state reads. A normal `terraform plan` cannot mock Azure providers.
    const test = [chdir, 'test', '-filter=tests/local.tftest.hcl', '-no-color'];
    if (operation === 'plan') test.push('-verbose');
    if (invoke(test, name) !== 0) failed.push(name);
  }
  if (dryRun) log('Dry run only: no commands were executed and no cloud checks were performed.');
  else {
    if (failed.length) error(`Checks failed: ${failed.join(', ')}`);
    else log(`Local ${operation === 'verify' ? 'verification' : 'mock plan'} passed: ${selected.join(', ')}. No cloud resources were read or changed.`);
  }
  return failed.length ? 1 : 0;
}
