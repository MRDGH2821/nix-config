#!/usr/bin/env bash

set -euo pipefail

REPODIR="$(git rev-parse --show-toplevel)"
cd "${REPODIR}"

_c2n_generate() {
  local dir="$1"
  local input="$2"
  echo "c2n: ${dir}/${input} -> ${dir}/podman-compose.nix"
  (
    cd "${dir}" || return 1
    compose2nix \
      -include_env_files=true \
      -env_files_only=true \
      -inputs "${input}" \
      -output podman-compose.nix \
      -root_path /etc/nixos/persist/
  )
}

c2n() {
  local root="${1:-.}"
  local dir input found=0

  if [[ -f "${root}" ]]; then
    _c2n_generate "$(dirname "${root}")" "$(basename "${root}")"
    return
  fi

  if [[ ! -d "${root}" ]]; then
    echo "c2n: not found: ${root}" >&2
    return 1
  fi

  while IFS= read -r dir; do
    for input in docker-compose.yml docker-compose.yaml compose.yaml compose.yml; do
      if [[ -f "${dir}/${input}" ]]; then
        _c2n_generate "${dir}" "${input}"
        found=1
        break
      fi
    done
  done < <(find "${root}" -type f \( -name docker-compose.yml -o -name docker-compose.yaml \) -exec dirname {} \; | sort -u)

  if [[ "${found}" -eq 0 ]]; then
    echo "c2n: no compose files under ${root}" >&2
    return 1
  fi
}

c2n "$@"
