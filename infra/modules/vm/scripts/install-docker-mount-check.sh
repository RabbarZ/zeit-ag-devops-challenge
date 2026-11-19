#!/bin/bash
# See docs/incidents.md.
#
# Installs a boot-time systemd oneshot that verifies the Docker data disk is
# mounted at /mnt/docker BEFORE docker.service starts. Refuses to auto-mount
# when the OS-disk /mnt/docker directory already has non-trivial data —
# preventing the shadow-mount corruption that hid 23 GB of live Docker state
# on demo when fstab drifted from /mnt/docker to /mnt/data after a reboot.
#
# Idempotent: safe to re-run on every terraform apply.
set -euo pipefail

RUNTIME_SCRIPT=/usr/local/sbin/acme-docker-mount-check.sh
UNIT_PATH=/etc/systemd/system/acme-docker-mount-check.service
DROPIN_DIR=/etc/systemd/system/docker.service.d
DROPIN_PATH="$DROPIN_DIR/require-mount-check.conf"

install -m 0755 /dev/stdin "$RUNTIME_SCRIPT" <<'SCRIPT_EOF'
#!/bin/bash
# Boot-time guard: ensure the Docker data disk is mounted at /mnt/docker.
# Refuses to auto-mount when /mnt/docker on the OS disk already has data —
# that would shadow live Docker/containerd state.
#
# Escape hatch: `touch /var/lib/acme-skip-mount-check` to bypass.
set -euo pipefail

LOG=/var/log/acme-docker-mount-check.log
log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG"; }

CANON=/mnt/docker

if [[ -f /var/lib/acme-skip-mount-check ]]; then
  log "SKIP: /var/lib/acme-skip-mount-check present — bypassing."
  exit 0
fi

if findmnt "$CANON" >/dev/null 2>&1; then
  SRC=$(findmnt -no SOURCE "$CANON")
  count=$(findmnt -rn -S "$SRC" -o TARGET | wc -l)
  if [[ "$count" -gt 1 ]]; then
    log "REFUSE: Docker disk $SRC is mounted at $count paths (double-mount hazard)."
    findmnt -rn -S "$SRC" -o TARGET | while read -r t; do log "  mount: $t"; done
    exit 1
  fi
  log "OK: $CANON mounted from $SRC."
  exit 0
fi

# Not mounted. Any non-trivial data on the OS-disk copy of /mnt/docker means
# Docker has been writing to the OS root — never auto-mount over it.
if [[ -d "$CANON" ]]; then
  entries=$(find "$CANON" -mindepth 1 -maxdepth 1 ! -name lost+found -printf . | wc -c)
  if [[ "$entries" -gt 0 ]]; then
    log "REFUSE: $CANON has $entries entries on the OS disk but the data disk is unmounted."
    log "Migrate the data first (see docs/incidents.md), then reboot."
    exit 1
  fi
fi

# Empty target. Try to find and mount the Docker data disk by scanning scsi1 LUNs.
mkdir -p "$CANON"
for lun_path in /dev/disk/azure/scsi1/lun*; do
  [[ -e "$lun_path" ]] || continue
  dev=$(readlink -f "$lun_path")
  [[ -b "$dev" ]] || continue
  if findmnt -S "$dev" >/dev/null 2>&1; then continue; fi
  fstype=$(blkid -s TYPE -o value "$dev" 2>/dev/null || echo "")
  [[ "$fstype" == "ext4" ]] || continue

  probe=$(mktemp -d /tmp/acme-docker-probe.XXXXXX)
  if mount -o ro "$dev" "$probe" 2>/dev/null; then
    if [[ -d "$probe/docker" || -d "$probe/containerd" ]]; then
      umount "$probe"
      rmdir "$probe"
      log "Mounting Docker data disk $dev at $CANON."
      mount "$dev" "$CANON"

      uuid=$(blkid -s UUID -o value "$dev")
      if ! grep -q "UUID=$uuid[[:space:]]\+$CANON[[:space:]]" /etc/fstab; then
        sed -i "\|UUID=$uuid|d; \|[[:space:]]$CANON[[:space:]]|d" /etc/fstab
        echo "UUID=$uuid $CANON ext4 defaults,nofail,discard 0 2" >> /etc/fstab
        log "fstab repaired: UUID=$uuid -> $CANON"
      fi
      log "OK: $CANON mounted from $dev."
      exit 0
    fi
    umount "$probe"
  fi
  rmdir "$probe" 2>/dev/null || true
done

# Nothing suitable found. Cloud-init handles first-boot format+mount; allow
# docker to start so fresh VMs are not blocked. Later boots on drifted VMs
# hit the REFUSE branches above and page a human.
log "No Docker data disk found. Allowing docker.service to proceed."
exit 0
SCRIPT_EOF

install -m 0644 /dev/stdin "$UNIT_PATH" <<'UNIT_EOF'
[Unit]
Description=Acme Planner docker data disk mount check
Documentation=file:///var/log/acme-docker-mount-check.log
Before=docker.service containerd.service
After=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/acme-docker-mount-check.sh

[Install]
WantedBy=multi-user.target
UNIT_EOF

mkdir -p "$DROPIN_DIR"
install -m 0644 /dev/stdin "$DROPIN_PATH" <<'DROPIN_EOF'
[Unit]
Requires=acme-docker-mount-check.service
After=acme-docker-mount-check.service
DROPIN_EOF

systemctl daemon-reload
systemctl enable acme-docker-mount-check.service

# Run it once now to surface any existing drift. Do NOT fail the terraform
# run-command if the check refuses — the point of exit 1 is to prevent docker
# from starting, not to break the apply.
systemctl start acme-docker-mount-check.service \
  || echo "[install-docker-mount-check] Mount check reported drift — see /var/log/acme-docker-mount-check.log"

echo "[install-docker-mount-check] Done."
