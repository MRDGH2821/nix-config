# Numtide Blueprint Migration Design Specification

- **Date**: 2026-07-25
- **Branch**: `refactor/blueprint`
- **Target Framework**: `github:numtide/blueprint`

## 1. Overview

This document specifies the migration of the `nix-config` homelab repository from a traditional `flake.nix` output structure to Numtide Blueprint (`blueprint.lib.flake`) with `prefix = "nix"`. 

The objective is to eliminate flake boilerplate, automate host and module discovery, and ensure `just check` (`nix flake check`) cleanly passes.

---

## 2. Flake Architecture (`flake.nix`)

`flake.nix` will be refactored into a concise entrypoint:

```nix
{
  description = "NixOS Homelab Configuration with Numtide Blueprint";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    alejandra.url = "github:kamadorueda/alejandra";
    authentik-nix.url = "github:nix-community/authentik-nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.url = "github:aksiksi/compose2nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-cli.url = "github:nix-community/nixos-cli";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
    treefmt.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs:
    inputs.blueprint.lib.flake {
      inherit inputs;
      prefix = "nix";
      nixpkgs.config.allowUnfree = true;
    };
}
```

---

## 3. Directory Layout & Host Configurations (`nix/hosts/`)

Blueprint scans subdirectories under `nix/hosts/` and generates `nixosConfigurations.<hostname>`.

### 3.1 `nix/hosts/home-lab/default.nix`
The entry point for `home-lab` host configuration:
- Accepts `{ inputs, pkgs, lib, config, ... }`.
- Imports:
  - `./configuration.nix`
  - `./hardware-configuration.nix`
  - `inputs.sops-nix.nixosModules.sops`
  - `inputs.authentik-nix.nixosModules.default`
  - `inputs.hermes-agent.nixosModules.default`
  - Host-specific modules in `./modules/`
  - All shared NixOS system modules from `nix/modules/nixos/`

### 3.2 `nix/hosts/test-bed/default.nix`
The entry point for `test-bed` host configuration, following the same module pattern.

---

## 4. Custom Library & Module Auto-Discovery

1. **`nix/lib/default.nix`**:
   - Aggregates helpers from `auto-import.nix`, `domain-builder.nix`, and `rclone-mounts.nix`.
   - Blueprint exports this file as `outputs.lib`.

2. **`nix/modules/nixos/`**:
   - Modularized NixOS features (`services/`, `container-services/`, `features/`, `fixes/`, `shell/`).
   - Exposed by Blueprint as `nixosModules`.

3. **`nix/modules/home/`**:
   - Home Manager configuration modules (`mr-nix.nix`).
   - Exposed by Blueprint as `homeModules`.

---

## 5. Devshell, Formatter, and Flake Checks

1. **`nix/devshell.nix`**:
   - Returns a `pkgs.mkShell` environment with `just`, `sops`, `alejandra`, `treefmt`, `copier`, `nixos-cli`.
   - Mapped by Blueprint to `devShells.${system}.default`.

2. **`nix/formatter.nix`**:
   - Defines standard code formatter using `treefmt-nix` / `alejandra`.
   - Mapped by Blueprint to `formatter.${system}`.

3. **`nix/checks/`**:
   - `nix/checks/formatting.nix`: Verifies code formatting.
   - `nix/checks/pre-commit-check.nix`: Runs pre-commit checks.
   - Mapped by Blueprint to `checks.${system}.*`.

---

## 6. Verification Plan

- Run `just check` (`nix flake check`) to ensure all flake outputs, hosts, devshell, and checks evaluate without errors.
- Verify `nix eval .#nixosConfigurations.home-lab.config.system.build.toplevel` evaluates cleanly.
- Commit all changes with Conventional Commit format and `Co-authored-by` trailer.
