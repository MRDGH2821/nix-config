#!/usr/bin/env bash
# Try to lock encrypted files before pushing. If git-agecrypt isn't installed,
# warn and allow push.
if command -v git-agecrypt >/dev/null 2>&1; then
    echo "Running git-agecrypt lock before push"
    git-agecrypt lock || echo "git-agecrypt lock failed; ensure files are encrypted before pushing"
else
    echo "git-agecrypt not found; aborting push to avoid committing unencrypted secrets"
    exit 1
fi
