#!/usr/bin/env bash

# Fix permissions for the Nix store
sudo chown -R "$USER":root /nix/*
