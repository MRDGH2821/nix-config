#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

BACKUP="/etc/nixos/persist/backups/homelab-$(date --iso-8601=date)"
DEST="${BACKUP}/forgejo-$(date +%H%M%S)"
forgejo_stopped=false

cleanup() {
  local result=$?
  trap - EXIT

  if [[ ${forgejo_stopped} == true ]]; then
    systemctl start forgejo.service || {
      echo "Failed to restart Forgejo." >&2
      result=1
    }
  fi

  exit "${result}"
}
trap cleanup EXIT

umask 077
mkdir -p "${BACKUP}"
mkdir "${DEST}"

forgejo_stopped=true
systemctl stop forgejo.service

# The script runs as root, so the redirect writes as root.
# shellcheck disable=SC2024
sudo -u postgres pg_dump -Fc forgejo > "${DEST}/forgejo.dump"
tar --acls --xattrs -cpf "${DEST}/forgejo-files.tar" \
  -C / var/lib/forgejo

pg_restore --list "${DEST}/forgejo.dump" >/dev/null

# Check the complete archive and confirm the repository directory is present.
tar -tf "${DEST}/forgejo-files.tar" > "${DEST}/archive-contents.txt"
if ! grep -q '^var/lib/forgejo/repositories/' "${DEST}/archive-contents.txt"; then
  echo "Repository directory is missing from the backup archive." >&2
  exit 1
fi
rm "${DEST}/archive-contents.txt"

echo "Forgejo backup created: ${DEST}"
echo "Repository directory found in the archive."
