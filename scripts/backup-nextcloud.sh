#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

BACKUP="/etc/nixos/persist/backups/homelab-$(date --iso-8601=date)"
DEST="${BACKUP}/nextcloud-$(date +%H%M%S)"
maintenance_enabled=false
cron_stopped=false

cleanup() {
  local result=$?
  trap - EXIT

  if [[ ${maintenance_enabled} == true ]]; then
    nextcloud-occ maintenance:mode --off || {
      echo "Failed to disable Nextcloud maintenance mode." >&2
      result=1
    }
  fi

  if [[ ${cron_stopped} == true ]]; then
    systemctl start nextcloud-cron.timer || {
      echo "Failed to restart the Nextcloud timer." >&2
      result=1
    }
  fi

  exit "${result}"
}
trap cleanup EXIT

umask 077
mkdir -p "${BACKUP}"
mkdir "${DEST}"

maintenance_enabled=true
nextcloud-occ maintenance:mode --on

cron_stopped=true
systemctl stop nextcloud-cron.timer
systemctl stop nextcloud-cron.service

# The script runs as root, so the redirect writes as root.
# shellcheck disable=SC2024
sudo -u postgres pg_dump -Fc nextcloud >"${DEST}/nextcloud.dump"
tar --acls --xattrs -cpf "${DEST}/nextcloud-files.tar" \
  -C / var/lib/nextcloud

pg_restore --list "${DEST}/nextcloud.dump" >/dev/null
tar -tf "${DEST}/nextcloud-files.tar" >/dev/null

echo "Nextcloud backup created: ${DEST}"
