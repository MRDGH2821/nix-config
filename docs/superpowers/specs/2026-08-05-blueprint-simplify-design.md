# Blueprint Simplify Design Specification

- **Date**: 2026-08-05
- **Branch**: `refactor/blueprint`
- **Target**: Simplify post-migration Nix layout toward Numtide Blueprint-native patterns
- **Related**: [2026-07-25 blueprint migration design](./2026-07-25-numtide-blueprint-migration-design.md)
- **Docs**: [Install](https://numtide.github.io/blueprint/main/getting-started/install/), [Folder structure](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)

## 1. Overview

Blueprint is already the flake entrypoint (`inputs.blueprint { prefix = "nix"; … }`). Hosts and helpers still use pre-Blueprint escape hatches and a dual custom lib API (`mylib` / `mylibFor`). Partial WIP from other agents introduced broken syntax and incomplete renames.

**Phase 1 goal:** simplify NixOS structure with Blueprint-native hosts and modules, plain lib helpers, and declarative rclone mounts so `just check` (`nix flake check`) passes.

**Phase 2 (separate plan and commits):** Home Manager via Blueprint `hosts/<host>/users/`.

### 1.1 Success criteria

- `just check` / `nix flake check` passes
- Hosts are normal Blueprint `configuration.nix` modules (no `class` / `value` / manual `nixosSystem`)
- No `mylib`, `mylibFor`, or `_module.args` injection for a dual lib API
- Shared options live under `nix/modules/nixos/` (Blueprint-discovered)
- Auto-import remains a single simple surface on `flake.lib`
- Rclone mounts are declared via `my.rclone.mounts`
- URL building uses `flake.lib.mkUrl` / `mkSubdomain`

### 1.2 Non-goals (Phase 1)

- Home Manager `hosts/*/users/` migration (Phase 2)
- Service behavior changes, new services, copier/template work
- Finishing the broken uncommitted `nixLib` rename as-is
- Making `test-bed` a minimal module subset (optional later; not required)

### 1.3 Baseline

Discard broken uncommitted Nix WIP (corrupted host files, `././` paths, incomplete rename). Rewrite from the last good committed tree on `refactor/blueprint`.

---

## 2. Decisions

| Topic | Choice |
|-------|--------|
| Barrel imports | Keep simple auto-import on `flake.lib` only |
| Host entry | Blueprint-native `configuration.nix`; delete escape-hatch `default.nix` |
| Shared NixOS wiring | **Approach 2:** each host lists `flake.modules.nixos.*` explicitly (no mega-facade `modules/nixos/default.nix`) |
| `default.nix` retention | Keep only as local auto-import aggregators; drop when Blueprint already maps that role |
| `nix/vars/` | Move to `nix/modules/nixos/vars/` |
| Rclone | NixOS module options: `my.rclone.mounts` |
| URLs | Lib functions: `flake.lib.mkUrl` / `mkSubdomain` |
| Home Manager | Phase 2, separate design/plan/commits |

---

## 3. Target layout

```text
flake.nix                          # keep: inputs.blueprint { prefix = "nix"; … }

nix/
  checks/
  devshell.nix
  formatter.nix
  treefmt.nix
  lib/
    default.nix                    # autoImport* + mkUrl/mkSubdomain → outputs.lib
    auto-import.nix
    # rclone-mounts.nix            DELETE after module lands
    # domain-builder.nix           fold into default.nix (or delete once folded)
  modules/
    nixos/
      # default.nix                DELETE (no facade under Approach 2)
      features/                    # + rclone-mounts.nix
      services/
      shell/
      fixes/
      container-services/
      vars/                        # moved from nix/vars/
        default.nix                # autoImportModules
        networking.nix
        mr-nix-user.nix
        forgejo-runner.nix
    home/                          # Phase 2; touch only if check forces
  hosts/
    home-lab/
      configuration.nix            # sole host entry
      hardware-configuration.nix
      modules/                     # host-only (+ barrel if useful)
      secrets/
      # default.nix                DELETE
    test-bed/
      configuration.nix
      hardware-configuration.nix
      # default.nix                DELETE
  keys/                            # plain files; import where needed
  # vars/                          DELETE after move
```

---

## 4. Hosts (Blueprint-native)

Blueprint loads `hosts/<name>/configuration.nix` and produces `nixosConfigurations.<name>` plus host checks. Module arguments include `flake`, `inputs`, `hostName`, and `perSystem`. Manual `specialArgs` for `inputs` / `hostName` is redundant and must not be reintroduced.

### 4.1 Shape

```nix
{ flake, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    # host-local only (home-lab):
    ./modules
    ./secrets/agecrypt/smtp.nix
    ./secrets/agecrypt/duckdns-domain.nix

    # Shared stack — explicit (Approach 2)
    flake.modules.nixos.features
    flake.modules.nixos.services
    flake.modules.nixos.shell
    flake.modules.nixos.fixes
    flake.modules.nixos.container-services
    flake.modules.nixos.vars

    inputs.sops-nix.nixosModules.sops
    inputs.authentik-nix.nixosModules.default
    inputs.hermes-agent.nixosModules.default
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  # existing host settings from today's configuration.nix remain here
}
```

### 4.2 Host differences

- **home-lab:** full shared list + host modules + agecrypt secrets as today.
- **test-bed:** same module-list pattern; omit host-only paths it does not use. Both hosts may start with the full shared list for parity; trimming test-bed is optional later.

### 4.3 `default.nix` retention rules

| Keep | Drop |
|------|------|
| Folder barrels that only `autoImportModules` / `autoImportFolders` so nested `.nix` files load under one Blueprint module name (`services/`, `features/`, `container-services/`, host `modules/`, `vars/`) | Host escape hatch `default.nix` (`class` / `value` / `nixosSystem`) |
| | `modules/nixos/default.nix` facade or `_module.args` lib injection |
| | Any `default.nix` that only re-exports a single Blueprint leaf |

---

## 5. Library and helpers

### 5.1 `nix/lib/default.nix`

Blueprint exports this as `outputs.lib` / `flake.lib`. Arguments: `{ flake, inputs }`.

Contents:

1. **Auto-import** (from `auto-import.nix` with `inputs.nixpkgs.lib`):
   - `autoImportModules`
   - `autoImportFolders`
2. **URL builders** (no `config` capture):
   - `mkSubdomain = baseDomain: subdomain: "…"`
   - `mkUrl = baseDomain: subdomain: secure: "…"`

Remove rclone from lib. Fold `domain-builder.nix` into the above (or delete after fold). No dual API, no `mylibFor`.

### 5.2 Barrel modules

Preferred:

```nix
{ flake, ... }: {
  imports = flake.lib.autoImportModules ./.;
}
```

For directories of service folders:

```nix
{ flake, ... }: {
  imports = flake.lib.autoImportFolders ./.;
}
```

Blueprint invokes modules that accept `flake` and/or `inputs` before exporting them. Prefer that over `_module.args`.

**Fallback** if a nested barrel does not receive `flake`: import auto-import with `inputs.nixpkgs.lib` at that edge only, or list imports explicitly for that folder. Prefer proving the `flake` form via `flake check` first.

### 5.3 URL call sites

```nix
{ config, flake, ... }:
let
  mkUrl = flake.lib.mkUrl config.networking.baseDomain;
in {
  # href = mkUrl "navidrome" true;
}
```

Primary consumer in Phase 1: `hosts/home-lab/modules/homepage-dashboard.nix`.

---

## 6. Rclone NixOS module

### 6.1 Location

`nix/modules/nixos/features/rclone-mounts.nix` (loaded via the `features` barrel into `flake.modules.nixos.features`).

### 6.2 Interface

Option path: **`my.rclone.mounts`** (avoids clashing with a future upstream `services.rclone`).

```nix
options.my.rclone.mounts = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
    options = {
      remoteName = lib.mkOption { type = lib.types.str; };
      folderName = lib.mkOption { type = lib.types.str; default = "/"; };
      mountPoint = lib.mkOption { type = lib.types.str; };
      options = lib.mkOption { type = lib.types.str; default = ""; };
      configFile = lib.mkOption {
        type = lib.types.path;
        # default matches current helper
        default = config.sops.secrets.rclone.path;
      };
    };
  }));
  default = {};
};
```

### 6.3 Implementation

Port existing `lib/rclone-mounts.nix` behavior: install `pkgs.rclone`, generate `systemd.mounts` and `systemd.automounts` with the same option string pattern (`_netdev`, `args2env`, `allow_other`, `vfs-cache-mode=full`, user options, `config=`).

### 6.4 Consumers

Replace helper `imports = [ (rcloneMount {…}) ]` with attr declarations:

| File | Action |
|------|--------|
| `modules/nixos/services/jellyfin.nix` | `my.rclone.mounts.jellyfin-*` |
| `modules/nixos/services/navidrome.nix` | `my.rclone.mounts.navidrome-*` |
| `hosts/home-lab/modules/desktop.nix` | Keepass mount via `my.rclone.mounts` |

Hosts that declare rclone mounts must still import `sops-nix` (home-lab does today).

---

## 7. Vars migration

Move `nix/vars/**` → `nix/modules/nixos/vars/**`.

- Barrel `default.nix` uses `flake.lib.autoImportModules`
- Hosts import `flake.modules.nixos.vars` (never `../../vars`)
- Delete `nix/vars/` after move
- Fix any remaining path references (grep for `vars`)

Option content (`networking.baseDomain`, `persistent_storage`, `mr-nix` user, forgejo-runner options) stays the same; only location and import path change.

---

## 8. Implementation order

1. Discard broken uncommitted Nix WIP; keep agent log updates as needed
2. Purify `nix/lib` (auto-import + URLs); remove dual API wiring
3. Add `my.rclone.mounts` module; migrate jellyfin, navidrome, desktop
4. Move `vars` under `modules/nixos/vars`; update barrels to `flake.lib`
5. Rewrite host `configuration.nix` with explicit `flake.modules.nixos.*`; delete host and facade `default.nix` files
6. Homepage: `flake.lib.mkUrl`
7. Grep for stale `mylib`, `mylibFor`, `nixLib`, `../../vars`, host escape hatch
8. Run `just check` until green

Prefer small logical commits if implementing incrementally; Phase 2 must not mix into Phase 1 commits.

---

## 9. Verification

| Check | Expectation |
|-------|-------------|
| `just check` | Passes |
| `nixosConfigurations.home-lab` / `test-bed` | Present and evaluate |
| No host escape hatch | No `class` / `value` / host-local `nixosSystem` |
| No dual lib | No `mylib` / `mylibFor` / `nixLib` injection |
| Module attrs | `features`, `services`, `shell`, `fixes`, `container-services`, `vars` under `flake.modules.nixos` |

Optional:

```bash
nix eval .#nixosConfigurations.home-lab.config.networking.hostName
```

---

## 10. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Nested barrels lack `flake` arg | Use Blueprint module wrap; fallback to lib-only auto-import or explicit imports |
| Host forgets a shared module | Start both hosts with full explicit list |
| Rclone `configFile` default before sops secret exists | Only declare mounts on hosts with sops + secret; keep default aligned with current helper |
| Stale paths after `vars` move | Grep and fix imports |
| Broken WIP pollutes rewrite | Reset Nix files from last good commit before editing |

---

## 11. Phase 2 (Home Manager) — deferred

Separate design and implementation plan; separate commits.

- Blueprint `hosts/<host>/users/<user>.nix` or `…/home-configuration.nix`
- Reuse shared config from `flake.modules.home.*` / `homeModules`
- `home-manager` input already present; do not fold into Phase 1

---

## 12. Relationship to prior migration

The 2026-07-25 migration design established Blueprint as the flake driver and the `prefix = "nix"` tree. This document **narrows and corrects** post-migration structure: remove escape-hatch hosts, remove dual lib glue, place options under Blueprint modules, and use explicit module imports instead of a single opaque `nixosModules.default` stack (Approach 2).
