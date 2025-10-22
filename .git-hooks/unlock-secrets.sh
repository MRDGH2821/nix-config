#!/usr/bin/env bash

if command -v git-agecrypt >/dev/null 2>&1; then
  echo "Running git-agecrypt unlock after checkout"
  git-agecrypt unlock || echo "git-agecrypt unlock failed; run 'git-agecrypt unlock' manually if needed"
fi
