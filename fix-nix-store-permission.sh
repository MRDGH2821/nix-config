#!/usr/bin/env bash

# Fix permissions for the Nix store
sudo chown -Rc "${USER}":root /nix/*
