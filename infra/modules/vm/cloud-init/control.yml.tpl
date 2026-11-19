#cloud-config
# Bootstrap for the control plane VM. Rendered by Terraform templatefile().
# The control API container is started here on first boot; later releases replace it from CI.

package_update: true
packages:
  - docker.io
  - docker-compose-v2
  - curl
  - jq
  - postgresql-client

groups:
  - docker

system_info:
  default_user:
    groups: [docker]

write_files:
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
          `
        }
      }

      import /etc/caddy/sites/*.caddy

  - path: /etc/caddy/sites/control.caddy
    owner: root:root
    permissions: '0644'
    content: |
      ${control_hostname} {
        import security_headers
        import waf
        reverse_proxy host.docker.internal:3300
      }

  - path: /opt/acme/compose.yml
    owner: root:root
    permissions: '0644'
    content: |
      ${indent(6, compose_yml)}

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

      cat > /etc/caddy/.env << CADDY_ENV
      AZURE_CONTAINER_REGISTRY=$${ACR_SERVER}
      AZURE_TENANT_ID=$(get_secret azure-tenant-id)
      AZURE_CLIENT_ID=$(get_secret azure-client-id)
      AZURE_CLIENT_SECRET=$(get_secret azure-client-secret)
      AZURE_SUBSCRIPTION_ID=$(get_secret azure-subscription-id)
      AZURE_RESOURCE_GROUP=$(get_secret dns-resource-group)
      CADDY_ENV
      chown root:docker /etc/caddy/.env && chmod 640 /etc/caddy/.env
      printf 'AZURE_CONTAINER_REGISTRY=%s\n' "$ACR_SERVER" > /opt/acme/.env

      echo "$(get_secret acr-password)" | docker login "$${ACR_SERVER}" -u "$(get_secret acr-username)" --password-stdin

      cd /opt/acme && docker compose -f compose.yml up -d

      CONTROL_DATABASE_URL=$(get_secret control-database-url)
      GITHUB_TOKEN=$(get_secret github-provisioning-token)
      docker pull "$${ACR_SERVER}/acme-control:latest"
      docker rm -f acme-control >/dev/null 2>&1 || true
      docker run -d --name acme-control --restart=always -p 3300:3300 \
        -e NODE_ENV=production \
        -e DATABASE_URL="$${CONTROL_DATABASE_URL}" \
        -e GITHUB_TOKEN="$${GITHUB_TOKEN}" \
        -e GITHUB_REPO="${github_repo}" \
        -e APP_URL="https://${control_hostname}" \
        "$${ACR_SERVER}/acme-control:latest"

      FINGERPRINT=$(ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256 | awk '{print $2}')
      curl -sSf -X PUT "https://$${VAULT_NAME}.vault.azure.net/secrets/vm-ssh-host-fingerprint?api-version=7.4" \
        -H "Authorization: Bearer $(kv_token)" -H "Content-Type: application/json" \
        -d "{\"value\":\"$FINGERPRINT\"}" >/dev/null

runcmd:
  - mkdir -p /etc/caddy/sites /opt/acme
  - /opt/acme/prepare-docker-disk.sh ${docker_disk_lun}
  - systemctl enable --now docker
  - bash -c 'set -o pipefail; /opt/acme/bootstrap.sh 2>&1 | tee -a /var/log/acme-bootstrap.log'
