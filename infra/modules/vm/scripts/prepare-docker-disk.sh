#!/bin/bash
# Usage: prepare-docker-disk.sh <lun>. Moves Docker's data-root onto the dedicated disk before docker starts.
set -euo pipefail

LUN="$1"
DEVICE=$(readlink -f "/dev/disk/azure/scsi1/lun${LUN}")

systemctl stop docker docker.socket containerd 2>/dev/null || true
blkid "$DEVICE" >/dev/null 2>&1 || mkfs.ext4 -F -L acme-docker "$DEVICE"

mkdir -p /mnt/docker
UUID=$(blkid -s UUID -o value "$DEVICE")
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /mnt/docker ext4 defaults,nofail,discard 0 2" >> /etc/fstab
mount -a

mkdir -p /etc/docker
printf '{\n  "data-root": "/mnt/docker/docker"\n}\n' > /etc/docker/daemon.json
systemctl start containerd docker
