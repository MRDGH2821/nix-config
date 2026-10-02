#!/bin/sh
# Fail if Zed's terminal always_allow list returns.
# GNU sed's e instruction and awk's system() can run another program.
# Issue #7: the owner said this allow list can be deleted entirely.
set -eu
root=$(CDPATH='' cd -- "$(dirname "$0")/../../.." && pwd)
zed=$root/nix/modules/home/zed.nix

if grep -F 'always_allow' "$zed" >/dev/null; then
  echo "terminal always_allow list is present" >&2
  exit 1
fi

if grep -F '{pattern = "^sed\\b";}' "$zed" >/dev/null; then
  echo "blanket sed approval is present" >&2
  exit 1
fi

if grep -F '{pattern = "^awk\\s+\\{print(\\s|$)";}' "$zed" >/dev/null; then
  echo "awk print-prefix approval is present" >&2
  exit 1
fi

probe=$(printf 'x\n' | sed -n '1e printf VERIFIER_SED_PROBE')
if [ "$probe" != "VERIFIER_SED_PROBE" ]; then
  echo "sed e probe did not run" >&2
  exit 1
fi

echo ok
