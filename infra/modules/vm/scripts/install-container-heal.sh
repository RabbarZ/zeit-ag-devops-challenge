#!/bin/bash
# See docs/incidents.md.
set -euo pipefail

UNIT_PATH=/etc/systemd/system/acme-container-heal.service

cat > "$UNIT_PATH" <<'EOF'
[Unit]
Description=Acme Planner container restart-policy heal + start-on-boot
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'NAMES=$(docker ps -a --filter "name=^acme-" --format "{{.Names}}"); if [ -n "$NAMES" ]; then echo "$NAMES" | xargs -r docker update --restart=always >/dev/null 2>&1 || true; echo "$NAMES" | xargs -r docker start >/dev/null 2>&1 || true; fi'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable acme-container-heal.service
systemctl start acme-container-heal.service

echo "[install-container-heal] Done."
