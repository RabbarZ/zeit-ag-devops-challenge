#cloud-config
# Bootstrap for an app environment VM. Rendered by Terraform templatefile().
# No secrets in this file: bootstrap.sh reads them from Key Vault with the VM's managed identity.

package_update: true
packages:
  - docker.io
  - docker-compose-v2
  - curl
  - jq

groups:
  - docker

system_info:
  default_user:
    groups: [docker]

write_files:
  - path: /etc/sysctl.d/99-acme.conf
    owner: root:root
    permissions: '0644'
    content: |
      vm.overcommit_memory = 1

  - path: /etc/caddy/Caddyfile
    owner: root:root
    permissions: '0644'
    content: |
      {
        email ops@planner.example
        order coraza_waf first
      }

      (security_headers) {
        header {
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          Referrer-Policy "strict-origin-when-cross-origin"
          Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
          -Server
        }
      }

      (dns_challenge) {
        tls {
          dns azure {
            tenant_id {$$AZURE_TENANT_ID}
            client_id {$$AZURE_CLIENT_ID}
            client_secret {$$AZURE_CLIENT_SECRET}
            subscription_id {$$AZURE_SUBSCRIPTION_ID}
            resource_group_name {$$AZURE_RESOURCE_GROUP}
          }
        }
      }

      (waf) {
        coraza_waf {
          load_owasp_crs
          directives `
            SecRuleEngine DetectionOnly
            SecRequestBodyAccess On
            SecRequestBodyLimit 10485760
            SecRequestBodyLimitAction Reject
            SecAuditEngine RelevantOnly
            SecRule REQUEST_HEADERS:Content-Type "@rx application/json" \
              "id:9000001,phase:1,pass,nolog,ctl:requestBodyProcessor=JSON"
          `
        }
      }

      import /etc/caddy/sites/*.caddy

  - path: /opt/acme/compose.yml
    owner: root:root
    permissions: '0644'
    content: |
      ${indent(6, compose_yml)}

  - path: /opt/acme/alloy/config.alloy
    owner: root:root
    permissions: '0644'
    content: |
      ${indent(6, alloy_config)}

  - path: /opt/acme/prepare-docker-disk.sh
    owner: root:root
    permissions: '0755'
    content: |
      ${indent(6, docker_disk_script)}

  - path: /opt/acme/bootstrap.sh
    owner: root:root
    permissions: '0700'
    content: |
      #!/bin/bash
      set -euo pipefail

      VAULT_NAME="${keyvault_name}"
      ACR_SERVER="${acr_login_server}"

      # Key Vault RBAC can take a minute to reach the VM, so every read retries.
      kv_token() {
        curl -sS 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' \
          -H 'Metadata: true' | jq -r '.access_token'
      }

      get_secret() {
        local name="$1" attempt response
        for attempt in $(seq 1 30); do
          if response=$(curl -sSf "https://$${VAULT_NAME}.vault.azure.net/secrets/$${name}?api-version=7.4" \
            -H "Authorization: Bearer $(kv_token)" 2>/dev/null); then
            echo "$response" | jq -r '.value'
            return 0
          fi
          sleep 20
        done
        echo "[bootstrap] could not read secret $${name}" >&2
        return 1
      }

      put_secret() {
        curl -sSf -X PUT "https://$${VAULT_NAME}.vault.azure.net/secrets/$1?api-version=7.4" \
          -H "Authorization: Bearer $(kv_token)" \
          -H "Content-Type: application/json" \
          -d "{\"value\":\"$2\"}" >/dev/null
      }

      cat > /etc/caddy/.env << CADDY_ENV
      AZURE_CONTAINER_REGISTRY=$${ACR_SERVER}
      AZURE_TENANT_ID=$(get_secret azure-tenant-id)
      AZURE_CLIENT_ID=$(get_secret azure-client-id)
      AZURE_CLIENT_SECRET=$(get_secret azure-client-secret)
      AZURE_SUBSCRIPTION_ID=$(get_secret azure-subscription-id)
      AZURE_RESOURCE_GROUP=$(get_secret dns-resource-group)
      CADDY_ENV
      chown root:docker /etc/caddy/.env && chmod 640 /etc/caddy/.env

      cat > /opt/acme/.env << APP_ENV
      AZURE_CONTAINER_REGISTRY=$${ACR_SERVER}
      REDIS_PASSWORD=$(get_secret redis-password)
      LOKI_REMOTE_URL=$(get_secret loki-endpoint || echo "")
      ENV_SLUG=${env_name}
      APP_ENV
      chmod 600 /opt/acme/.env

      echo "$(get_secret acr-password)" | docker login "$${ACR_SERVER}" -u "$(get_secret acr-username)" --password-stdin

      cd /opt/acme && docker compose -f compose.yml up -d

      FINGERPRINT=$(ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256 | awk '{print $2}')
      put_secret vm-ssh-host-fingerprint "$FINGERPRINT"

runcmd:
  - sysctl --system
  - mkdir -p /etc/caddy/sites /opt/acme/tenants
  - /opt/acme/prepare-docker-disk.sh ${docker_disk_lun}
  - systemctl enable --now docker
  - bash -c 'set -o pipefail; /opt/acme/bootstrap.sh 2>&1 | tee -a /var/log/acme-bootstrap.log'
