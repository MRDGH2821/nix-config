#!/usr/bin/env bash

set -euo pipefail

# Navigate to the root of the repository
REPODIR="$(git rev-parse --show-toplevel)"
cd "${REPODIR}"

echo "Running nix flake update..."
nix flake update

# Check if flake.lock has changed
# --quiet implies --exit-code and suppresses output
if git diff --quiet flake.lock; then
    echo "No changes to flake.lock. Nothing to commit."
else
    echo "flake.lock updated. Committing changes..."
    # Using --add for robustness if it was somehow not tracked,
    # though flake.lock should always be tracked.
    git add flake.lock
    git commit -S -m 'build(flake): update flake.lock'
    echo "Done."
fi
