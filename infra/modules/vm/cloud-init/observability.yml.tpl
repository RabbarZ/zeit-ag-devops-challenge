#cloud-config
# Bootstrap for the observability VM (LGTM stack). Rendered by Terraform templatefile().
# The compose file and the observability/ configs are copied to /opt/acme/observability by the deploy workflow.

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
  - path: /etc/caddy/Caddyfile
    owner: root:root
    permissions: '0644'
    content: |
      {
        email ops@planner.example
      }

      (security_headers) {
        header {
          X-Content-Type-Options "nosniff"
          Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
          -Server
        }
      }

      import /etc/caddy/sites/*.caddy

  - path: /etc/caddy/sites/grafana.caddy
    owner: root:root
    permissions: '0644'
    content: |
      ${grafana_hostname} {
        import security_headers
        reverse_proxy grafana:3000
      }

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

      cat > /opt/acme/observability/.env << OBS_ENV
      AZURE_CONTAINER_REGISTRY=$${ACR_SERVER}
      GRAFANA_ADMIN_PASSWORD=$(get_secret grafana-admin-password)
      OBS_ENV
      chmod 600 /opt/acme/observability/.env

      echo "$(get_secret acr-password)" | docker login "$${ACR_SERVER}" -u "$(get_secret acr-username)" --password-stdin

      FINGERPRINT=$(ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256 | awk '{print $2}')
      curl -sSf -X PUT "https://$${VAULT_NAME}.vault.azure.net/secrets/vm-ssh-host-fingerprint?api-version=7.4" \
        -H "Authorization: Bearer $(kv_token)" -H "Content-Type: application/json" \
        -d "{\"value\":\"$FINGERPRINT\"}" >/dev/null

runcmd:
  - mkdir -p /etc/caddy/sites /opt/acme/observability
  - /opt/acme/prepare-docker-disk.sh ${docker_disk_lun}
  - systemctl enable --now docker
  - |
    DATA_DEV=$(readlink -f /dev/disk/azure/scsi1/lun${data_disk_lun})
    blkid "$DATA_DEV" >/dev/null 2>&1 || mkfs.ext4 -F -L acme-logs "$DATA_DEV"
    UUID=$(blkid -s UUID -o value "$DATA_DEV")
    mkdir -p /mnt/logs
    grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /mnt/logs ext4 defaults,nofail 0 2" >> /etc/fstab
    mount -a
  - mkdir -p /mnt/logs/loki /mnt/logs/tempo /mnt/logs/prometheus /mnt/logs/grafana
  - chown -R 10001:10001 /mnt/logs/loki /mnt/logs/tempo
  - chown -R 65534:65534 /mnt/logs/prometheus
  - chown -R 472:472 /mnt/logs/grafana
  - bash -c 'set -o pipefail; /opt/acme/bootstrap.sh 2>&1 | tee -a /var/log/acme-bootstrap.log'
