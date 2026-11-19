// Credential-free local plans and verification using Terraform mock providers.
import { fileURLToPath } from 'node:url';
import { runInfra } from './lib/infra.mjs';

process.exitCode = runInfra({
  operation: process.argv[2],
  args: process.argv.slice(3),
  root: fileURLToPath(new URL('../', import.meta.url)),
});
