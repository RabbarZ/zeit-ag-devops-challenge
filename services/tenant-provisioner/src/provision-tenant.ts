// Excerpt of the control plane's tenant provisioner. The SSH transport is left out:
// any ShellExecutor that runs commands on the app VM can be passed in.

export interface ShellExecutor {
  run(command: string, options?: { redact?: string[] }): Promise<string>;
  writeFile(path: string, content: string): Promise<void>;
}

export interface TenantSpec {
  slug: string;
  image: string;
  host: string;
  databaseUrl: string;
  redisPassword: string;
}

const NETWORK = 'acme-app';

export async function provisionTenant(shell: ShellExecutor, tenant: TenantSpec): Promise<void> {
  const container = `acme-tenant-${tenant.slug}`;

  await shell.run(`docker pull ${tenant.image}`);
  await shell.run(`docker rm -f ${container}`).catch(() => undefined);
  await shell.run(
    [
      'docker run -d',
      `--name ${container}`,
      '--restart=always',
      `--network ${NETWORK}`,
      `-e TENANT_ID=${tenant.slug}`,
      `-e DATABASE_URL=${tenant.databaseUrl}`,
      `-e REDIS_URL=redis://:${tenant.redisPassword}@acme-redis:6379/0`,
      tenant.image,
    ].join(' '),
    { redact: [tenant.databaseUrl, tenant.redisPassword] },
  );

  await shell.writeFile(`/etc/caddy/sites/${tenant.slug}.caddy`, siteConfig(tenant));
  await shell.run('docker exec acme-caddy caddy reload --config /etc/caddy/Caddyfile');
  await shell.run(`docker exec ${container} wget -q -O /dev/null http://localhost:3000/api/health`);
}

function siteConfig(tenant: TenantSpec): string {
  return `${tenant.host} {\n  import waf\n  import security_headers\n  reverse_proxy acme-tenant-${tenant.slug}:3000\n}\n`;
}
