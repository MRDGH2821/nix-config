# Blueprint Simplify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify the post-Blueprint NixOS layout: native host `configuration.nix`, explicit `flake.modules.nixos.*` imports, pure `flake.lib` (auto-import + URL helpers), declarative `my.rclone.mounts`, and `vars` under Blueprint modules — so `just check` passes.

**Architecture:** Keep `flake.nix` as thin `inputs.blueprint { prefix = "nix"; … }`. Delete host escape-hatch `default.nix` files. Each host lists shared modules from `flake.modules.nixos`. Barrel `default.nix` files only aggregate siblings via `flake.lib.autoImport*`. Rclone becomes a NixOS options module under `features/`; URL builders stay pure functions on `flake.lib`.

**Tech Stack:** Nix, Flakes, Numtide Blueprint, NixOS, sops-nix, just.

**Spec:** [docs/superpowers/specs/2026-08-05-blueprint-simplify-design.md](../specs/2026-08-05-blueprint-simplify-design.md)

## Global Constraints

- Phase 1 only — do **not** implement Home Manager `hosts/*/users/` (Phase 2 separate plan).
- Do **not** change service behavior beyond import/helper rewires (same mounts, same URLs, same options).
- Discard broken uncommitted WIP under `nix/`; rewrite from last good committed tree (do not finish the broken `nixLib` rename).
- Prefer Blueprint-native syntax; no `class`/`value`/`nixosSystem` escape hatch on hosts after Task 6.
- No `mylib` / `mylibFor` / `_module.args` dual-lib injection after Task 6.
- Rclone option path is **`my.rclone.mounts`** only.
- Commits: Conventional Commits; include `Co-authored-by: Composer via Cursor <noreply@cursor.com>` on AI-assisted commits.
- After every task that changes Nix: run `just check` (or `nix flake check`) and only proceed when it passes — unless the task explicitly says evaluation is expected intermediate (none should leave a known-broken tree on commit).
- Valid scopes (from `cog.toml`): prefer `flake`, `hosts`, `hosts/home-lab`, `hosts/test-bed`, `services`, `features`, `variables`, `shell` as appropriate.

## File map

| Path | Role after plan |
|------|-----------------|
| `flake.nix` | Unchanged Blueprint entry |
| `nix/lib/default.nix` | `autoImportModules`, `autoImportFolders`, `mkUrl`, `mkSubdomain` |
| `nix/lib/auto-import.nix` | Unchanged logic |
| `nix/lib/domain-builder.nix` | **Delete** (folded into lib) |
| `nix/lib/rclone-mounts.nix` | **Delete** after module lands |
| `nix/modules/nixos/features/rclone-mounts.nix` | **Create** — `my.rclone.mounts` |
| `nix/modules/nixos/features/default.nix` | Barrel: `flake.lib.autoImportModules` |
| `nix/modules/nixos/services/default.nix` | Barrel |
| `nix/modules/nixos/services/jellyfin.nix` | Consume `my.rclone.mounts` |
| `nix/modules/nixos/services/navidrome.nix` | Consumer + keep `BaseUrl` string as-is or use `mkUrl` only if already present as string |
| `nix/modules/nixos/shell/default.nix` | Barrel |
| `nix/modules/nixos/fixes/default.nix` | Barrel |
| `nix/modules/nixos/container-services/default.nix` | Barrel `autoImportFolders` + firewall |
| `nix/modules/nixos/container-services/*/default.nix` | Nested barrels without `mylib` |
| `nix/modules/nixos/default.nix` | **Delete** |
| `nix/modules/nixos/vars/**` | **Moved from** `nix/vars/**` |
| `nix/vars/**` | **Delete** after move |
| `nix/hosts/home-lab/default.nix` | **Delete** |
| `nix/hosts/test-bed/default.nix` | **Delete** |
| `nix/hosts/home-lab/configuration.nix` | Sole entry + full import list |
| `nix/hosts/test-bed/configuration.nix` | Sole entry + full import list |
| `nix/hosts/home-lab/modules/*.nix` | desktop/homepage no mylib |
| `nix/modules/home/` | Phase 2 — touch only if check forces |

---

### Task 1: Discard broken Nix WIP

**Files:**

- Restore: all modified files under `nix/` to `HEAD` (committed good tree)
- Leave: `.agents/logs/`, design/plan docs, uncommitted log noise

**Interfaces:**

- Produces: clean baseline matching last `refactor/blueprint` commit under `nix/`

- [ ] **Step 1: Confirm which `nix/` files are dirty**

Run:

```bash
git status -- nix/
```

Expected: list of modified files under `nix/` from the incomplete agent WIP (hosts, modules, vars, etc.).

- [ ] **Step 2: Restore all `nix/` paths to HEAD**

Run:

```bash
git restore -- nix/
```

Expected: `git status -- nix/` shows a clean tree (no modifications under `nix/`).

- [ ] **Step 3: Sanity-check baseline still evaluates**

Run:

```bash
just check
```

Expected: success (same as before Phase 1 work). If this fails, stop and fix baseline first — do not proceed.

- [ ] **Step 4: Commit only if restore needed a committed mistake**

If Step 2 only discarded uncommitted changes, **no commit** (nothing staged). If you had to fix a committed break, commit that fix; otherwise continue.

---

### Task 2: Purify `nix/lib` (auto-import + URL helpers)

**Files:**

- Modify: `nix/lib/default.nix`
- Delete: `nix/lib/domain-builder.nix` (after fold)
- Keep: `nix/lib/auto-import.nix` (unchanged logic)
- Keep temporarily: `nix/lib/rclone-mounts.nix` until Task 3 consumers migrate (delete in Task 3)

**Interfaces:**

- Consumes: `inputs.nixpkgs.lib`, `./auto-import.nix`
- Produces (`flake.lib` / `outputs.lib`):
  - `autoImportModules :: path -> [path]`
  - `autoImportFolders :: path -> [path]`
  - `mkSubdomain :: string -> string -> string` — `mkSubdomain baseDomain subdomain`
  - `mkUrl :: string -> string -> bool -> string` — `mkUrl baseDomain subdomain secure`

**Note:** Hosts still use escape hatch + `mylib` until Task 6. Task 2 alone may break evaluation if `lib/default.nix` stops working as imported by `import ../../lib {inherit (inputs.nixpkgs) lib;}`. Adjust Task 2 implementation so **both** work until Task 6:

1. Blueprint form: `{ flake, inputs }: …` using `inputs.nixpkgs.lib`
2. Legacy host form temporarily still does `import ../../lib { inherit (inputs.nixpkgs) lib; }` in Task 1 baseline host `default.nix`

So implement lib as:

```nix
{
  flake ? null,
  inputs ? {},
  lib ? inputs.nixpkgs.lib or null,
  ...
}:
```

If `lib` is null and `inputs.nixpkgs` exists, take `inputs.nixpkgs.lib`. Prefer simple args that accept either Blueprint or the old import style.

- [ ] **Step 1: Rewrite `nix/lib/default.nix`**

Replace entire file with:

```nix
{
  inputs ? {},
  lib ? inputs.nixpkgs.lib,
  ...
}: let
  autoImport = import ./auto-import.nix {inherit lib;};
in
  autoImport
  // {
    inherit (autoImport) autoImportModules autoImportFolders;
    mkSubdomain = baseDomain: subdomain: "${subdomain}.${baseDomain}";
    mkUrl = baseDomain: subdomain: secure: let
      protocol =
        if secure
        then "https"
        else "http";
    in "${protocol}://${subdomain}.${baseDomain}";
  }
```

Do **not** export `domainBuilder` or `rcloneMounts` from this file anymore (rclone stays as a free-standing file only until Task 3 deletes it).

- [ ] **Step 2: Delete `nix/lib/domain-builder.nix`**

```bash
git rm nix/lib/domain-builder.nix
```

- [ ] **Step 3: Verify no remaining imports of domain-builder**

Run:

```bash
rg -n 'domain-builder|domainBuilder' nix/
```

Expected: only comments (if any) or zero hits under live code. If host `default.nix` still imports domain-builder for `mylibFor`, update hosts in this task to stop using domain-builder in the `mylibFor` merge:

Edit **both** `nix/hosts/home-lab/default.nix` and `nix/hosts/test-bed/default.nix` so `mylibFor` becomes only auto-import + rclone until Task 3/6 remove them:

```nix
mylibFor = args:
  mylib
  // (import ../../lib/rclone-mounts.nix args);
```

And ensure `mylib = import ../../lib { inherit (inputs.nixpkgs) lib; };` still provides `autoImportModules` / `autoImportFolders` / `mkUrl` (callers of `mylib.mkUrl` need `baseDomain` as first arg — **homepage still uses old arity** `mylib.mkUrl "x" true`). That arity break is intentional; fix homepage in Task 5 **before** or **with** the first commit that removes config-capturing mkUrl from specialArgs.

**Ordering fix inside this task:** keep `mylibFor` composing rclone only; keep homepage working by either:

**Option A (preferred for Task 2 green check):** Leave host files unchanged except remove domain-builder from the merge, and temporarily keep old-arity helpers only for mkUrl via a thin compat **not** preferred by the design.

**Option B:** In Task 2 only rewrite lib + delete domain-builder; update every `mkUrl` call site in the same task (homepage) and keep rclone via `mylibFor` until Task 3.

Use **Option B** so arity is correct:

- [ ] **Step 4: Update homepage for new `mkUrl` arity while still on mylibFor path**

In `nix/hosts/home-lab/modules/homepage-dashboard.nix`, replace:

```nix
  mylibFor,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
in {
```

with:

```nix
  ...
}: let
  mkUrl = subdomain: secure: let
    protocol =
      if secure
      then "https"
      else "http";
    domain = config.networking.baseDomain;
  in "${protocol}://${subdomain}.${domain}";
in {
```

Replace every `mylib.mkUrl` with `mkUrl` in that file. Remove unused `mylibFor` from the argument list. Remove unused `pkgs` only if unused after edit (keep if still used).

(This local function is temporary; Task 5 wires `flake.lib.mkUrl`.)

- [ ] **Step 5: Run check**

```bash
just check
```

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add nix/lib/default.nix nix/lib/domain-builder.nix \
  nix/hosts/home-lab/default.nix nix/hosts/test-bed/default.nix \
  nix/hosts/home-lab/modules/homepage-dashboard.nix
git commit -m "$(cat <<'EOF'
refactor(flake): purify lib with explicit URL helpers

Fold domain-builder into flake.lib-style mkUrl/mkSubdomain;
drop domain-builder file; keep rclone helper for next task.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 3: Add `my.rclone.mounts` and migrate consumers

**Files:**

- Create: `nix/modules/nixos/features/rclone-mounts.nix`
- Modify: `nix/modules/nixos/services/jellyfin.nix`
- Modify: `nix/modules/nixos/services/navidrome.nix`
- Modify: `nix/hosts/home-lab/modules/desktop.nix`
- Delete: `nix/lib/rclone-mounts.nix`
- Modify: host `default.nix` files — remove rclone from `mylibFor` once consumers no longer need it

**Interfaces:**

- Produces option: `my.rclone.mounts.<name>.{ remoteName, folderName, mountPoint, options, configFile }`
- Consumes: `config.sops.secrets.rclone.path` as default for `configFile`
- Behavior: same systemd mount/automount + `pkgs.rclone` as old helper

- [ ] **Step 1: Create rclone module**

Write `nix/modules/nixos/features/rclone-mounts.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.rclone.mounts;
in {
  options.my.rclone.mounts = lib.mkOption {
    default = {};
    description = "Declarative rclone systemd mounts";
    type = lib.types.attrsOf (
      lib.types.submodule (
        {name, ...}: {
          options = {
            configFile = lib.mkOption {
              default = config.sops.secrets.rclone.path;
              description = "Path to rclone config file";
              type = lib.types.path;
            };
            folderName = lib.mkOption {
              default = "/";
              description = "Remote folder path";
              type = lib.types.str;
            };
            mountPoint = lib.mkOption {
              description = "Local mount point";
              type = lib.types.str;
            };
            options = lib.mkOption {
              default = "";
              description = "Extra rclone mount options (comma-separated fragment)";
              type = lib.types.str;
            };
            remoteName = lib.mkOption {
              description = "rclone remote name";
              type = lib.types.str;
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (cfg != {}) {
    environment.systemPackages = [pkgs.rclone];
    systemd = {
      automounts =
        lib.mapAttrsToList (_name: m: {
          wantedBy = ["multi-user.target"];
          where = m.mountPoint;
        })
        cfg;
      mounts =
        lib.mapAttrsToList (_name: m: {
          options = "_netdev,args2env,allow_other,vfs-cache-mode=full,${m.options},config=${m.configFile}";
          type = "rclone";
          what = "${m.remoteName}:${m.folderName}";
          where = m.mountPoint;
        })
        cfg;
    };
  };
}
```

- [ ] **Step 2: Rewrite jellyfin consumer**

Replace `nix/modules/nixos/services/jellyfin.nix` with:

```nix
{
  services.jellyfin.enable = true;

  my.rclone.mounts = {
    jellyfin-kirtan = {
      folderName = "Kirtans";
      mountPoint = "/mnt/rclone/jellyfin/Kirtans";
      options = "ro";
      remoteName = "pcloud-personal";
    };
    jellyfin-music = {
      folderName = "Music";
      mountPoint = "/mnt/rclone/jellyfin/Music";
      options = "ro";
      remoteName = "pcloud-personal";
    };
  };
}
```

- [ ] **Step 3: Rewrite navidrome consumer**

Replace rclone helper usage; keep navidrome service settings:

```nix
{config, ...}: {
  my.rclone.mounts = {
    navidrome-kirtan = {
      folderName = "Kirtans";
      mountPoint = "/mnt/rclone/navidrome/Kirtans";
      options = "ro";
      remoteName = "pcloud-personal";
    };
    navidrome-music = {
      folderName = "Music";
      mountPoint = "/mnt/rclone/navidrome/Music";
      options = "ro";
      remoteName = "pcloud-personal";
    };
  };

  services.navidrome = {
    enable = false;
    openFirewall = true;
    settings = {
      BaseUrl = "https://navidrome.${config.networking.baseDomain}";
      MusicFolder = "/mnt/rclone/navidrome";
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
```

- [ ] **Step 4: Rewrite desktop Keepass mount**

Replace helper in `nix/hosts/home-lab/modules/desktop.nix` with:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
    keepassxc
  ];
  hardware.graphics.enable = true;
  my.rclone.mounts.keepassxc = {
    folderName = "Keepass";
    mountPoint = "/mnt/rclone/kpxc/Keepass";
    options = "rw";
    remoteName = "pcloud-personal";
  };
  services = {
    desktopManager.plasma6.enable = true;
    openssh.enable = true;
  };
  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
```

- [ ] **Step 5: Remove rclone helper file and host mylibFor rclone merge**

```bash
git rm nix/lib/rclone-mounts.nix
```

Simplify both host escape-hatch files so `mylibFor` is gone if nothing uses it. If homepage no longer needs mylibFor and only barrels need `mylib.autoImport*`, host `specialArgs` only needs:

```nix
specialArgs = {
  inherit inputs hostName mylib;
};
```

With:

```nix
mylib = import ../../lib {inherit (inputs.nixpkgs) lib;};
```

Delete the entire `mylibFor` let-binding and inheritance.

Grep to confirm no `mylibFor` / `rcloneMount` remain:

```bash
rg -n 'mylibFor|rcloneMount|rclone-mounts' nix/
```

Expected: only the new module path / option names.

- [ ] **Step 6: Run check**

```bash
just check
```

Expected: pass.

- [ ] **Step 7: Commit**

```bash
git add nix/modules/nixos/features/rclone-mounts.nix \
  nix/modules/nixos/services/jellyfin.nix \
  nix/modules/nixos/services/navidrome.nix \
  nix/hosts/home-lab/modules/desktop.nix \
  nix/hosts/home-lab/default.nix \
  nix/hosts/test-bed/default.nix \
  nix/lib/rclone-mounts.nix
git commit -m "$(cat <<'EOF'
feat(features): add declarative my.rclone.mounts module

Migrate jellyfin, navidrome, and desktop mounts; remove lib helper.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 4: Move `vars` into Blueprint modules

**Files:**

- Create: `nix/modules/nixos/vars/default.nix`, `networking.nix`, `mr-nix-user.nix`, `forgejo-runner.nix` (moved)
- Delete: `nix/vars/**`
- Modify: host `default.nix` modules lists — replace `../../vars` with `inputs.self.nixosModules.vars` **or** path that works until Task 6; preferred intermediate: `inputs.self.modules.nixos.vars` if that is how Blueprint exposes it; use `inputs.self.nixosModules.vars` when Blueprint maps `modules/nixos/vars` → `nixosModules.vars`

**Interfaces:**

- Produces: `flake.modules.nixos.vars` / `nixosModules.vars`
- Path fix in moved `mr-nix-user.nix`: `import ../keys/ssh-keys.nix` → `import ../../keys/ssh-keys.nix` (from `modules/nixos/vars/`)

- [ ] **Step 1: Create directory and move files**

```bash
mkdir -p nix/modules/nixos/vars
git mv nix/vars/networking.nix nix/modules/nixos/vars/
git mv nix/vars/mr-nix-user.nix nix/modules/nixos/vars/
git mv nix/vars/forgejo-runner.nix nix/modules/nixos/vars/
```

- [ ] **Step 2: Write barrel `nix/modules/nixos/vars/default.nix`**

Prefer flake-based auto-import (Blueprint wraps top-level modules with `flake` when the module function accepts it):

```nix
{flake, ...}: {
  imports = flake.lib.autoImportModules ./.;
  # persistent_storage lives here after move (was on old vars/default.nix)
}
```

Preserve `persistent_storage` option from old `nix/vars/default.nix`:

```nix
{flake, lib, ...}: {
  imports = flake.lib.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
    type = lib.types.str;
  };
}
```

If Blueprint does not pass `flake` into this module during evaluation, fall back to:

```nix
{lib, ...}: let
  auto = import ../../lib/auto-import.nix {inherit lib;};
in {
  imports = auto.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
    type = lib.types.str;
  };
}
```

- [ ] **Step 3: Fix relative path in `mr-nix-user.nix`**

Change:

```nix
sshKeys = import ../keys/ssh-keys.nix;
```

to:

```nix
sshKeys = import ../../keys/ssh-keys.nix;
```

- [ ] **Step 4: Remove old vars default and directory**

```bash
git rm -f nix/vars/default.nix
rmdir nix/vars 2>/dev/null || true
```

- [ ] **Step 5: Point hosts at new module**

In both host escape-hatch `default.nix` module lists, replace `../../vars` with:

```nix
inputs.self.nixosModules.vars
```

(If attribute missing under that path during check, try `inputs.self.modules.nixos.vars` and record which works in the commit message / this plan by editing the working path once verified.)

- [ ] **Step 6: Run check**

```bash
just check
```

Expected: pass.

- [ ] **Step 7: Commit**

```bash
git add nix/modules/nixos/vars nix/vars nix/hosts/home-lab/default.nix nix/hosts/test-bed/default.nix
git commit -m "$(cat <<'EOF'
refactor(variables): move shared options under modules/nixos/vars

Expose as Blueprint nixosModules.vars; fix keys path after move.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 5: Convert barrels to `flake.lib` auto-import

**Files:**

- Modify every barrel still using `mylib`:
  - `nix/modules/nixos/features/default.nix`
  - `nix/modules/nixos/services/default.nix`
  - `nix/modules/nixos/shell/default.nix`
  - `nix/modules/nixos/fixes/default.nix`
  - `nix/modules/nixos/container-services/default.nix`
  - `nix/modules/nixos/container-services/omni-tools/default.nix`
  - `nix/modules/nixos/container-services/vert-sh/default.nix`
  - `nix/modules/nixos/container-services/omniroute/default.nix` (keep redis/container config; only change import mechanism)
  - `nix/modules/nixos/container-services/honcho-memory/default.nix` (same)
  - `nix/hosts/home-lab/modules/default.nix`

**Interfaces:**

- Consumes: `flake.lib.autoImportModules` / `autoImportFolders`
- Removes dependence on `specialArgs.mylib` for these barrels

Pattern for module-list barrels:

```nix
{flake, ...}: {
  imports = flake.lib.autoImportModules ./.;
}
```

For `container-services/default.nix` (folders + firewall):

```nix
{flake, ...}: {
  imports = flake.lib.autoImportFolders ./.;
  networking.firewall = {
    extraCommands = "iptables -I nixos-fw 1 -i br+ -j ACCEPT";
    extraStopCommands = "iptables -D nixos-fw -i br+ -j ACCEPT";
    trustedInterfaces = ["br+"];
  };
}
```

For nested container barrels that also set service config (omniroute / honcho-memory): keep the existing non-import attrset body; only replace argument list + imports line:

```nix
{
  config,
  flake,
  ...
}: {
  imports = flake.lib.autoImportModules ./.;
  # ... remainder of file unchanged ...
}
```

Homepage: switch temporary local URL fn to flake.lib (works when `flake` is in module args / specialArgs).

If escape-hatch still lacks `flake`, add to host specialArgs:

```nix
specialArgs = {
  inherit inputs hostName mylib;
  flake = inputs.self;
};
```

Then homepage:

```nix
{ config, flake, ... }:
let
  mkUrl = flake.lib.mkUrl config.networking.baseDomain;
in {
  # use mkUrl "navidrome" true;
}
```

- [ ] **Step 1: Update all barrels listed above**

- [ ] **Step 2: Pass `flake = inputs.self` in both host specialArgs if needed**

- [ ] **Step 3: Update homepage to `flake.lib.mkUrl`**

- [ ] **Step 4: Grep for mylib leftovers in barrels**

```bash
rg -n 'mylib' nix/
```

Expected: only host `specialArgs` / temporary `mylib` for anything not yet converted; ideally only hosts until Task 6 deletes them. Nested modules must not take `mylib`.

- [ ] **Step 5: Run check**

```bash
just check
```

If barrels fail with “undefined variable `flake`”, switch those barrels to the lib-path fallback:

```nix
{lib, ...}: let
  auto = import ../../lib/auto-import.nix {inherit lib;};
in {
  imports = auto.autoImportModules ./.;
}
```

(adjust `../` depth: from `modules/nixos/features` use `../../lib/...`; from `container-services/omniroute` use `../../../lib/...`). Prefer flake form when it works.

- [ ] **Step 6: Commit**

```bash
git add nix/modules/nixos nix/hosts
git commit -m "$(cat <<'EOF'
refactor: wire barrels through flake.lib auto-import

Drop mylib module args for directory aggregators; use flake.lib URLs.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 6: Native hosts + delete escape hatches and facade

**Files:**

- Modify: `nix/hosts/home-lab/configuration.nix`
- Modify: `nix/hosts/test-bed/configuration.nix`
- Delete: `nix/hosts/home-lab/default.nix`
- Delete: `nix/hosts/test-bed/default.nix`
- Delete: `nix/modules/nixos/default.nix`

**Interfaces:**

- Hosts import explicit modules:

```nix
flake.modules.nixos.features
flake.modules.nixos.services
flake.modules.nixos.shell
flake.modules.nixos.fixes
flake.modules.nixos.container-services
flake.modules.nixos.vars
```

Plus host-local + external inputs (sops, authentik, hermes-agent).

- [ ] **Step 1: Rewrite `nix/hosts/home-lab/configuration.nix`**

Merge existing body with imports from the deleted escape hatch:

```nix
{
  flake,
  inputs,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
    ./hardware-configuration.nix
    ./modules
    ./secrets/agecrypt/smtp.nix
    ./secrets/agecrypt/duckdns-domain.nix

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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  networking = {
    hostName = "home-lab";
    networkmanager.enable = true;
  };

  nix.settings.allowed-users = [
    "@wheel"
    "bose-game"
  ];

  programs.ssh.startAgent = true;

  services = {
    automatic-timezoned.enable = true;
    openssh.enable = true;
  };

  system.stateVersion = "25.05";

  users.users.bose-game = {
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5wVbxASqs1YeVPFBzUoyNCABQFDOF0/JXxGrz2u215 Bose Game Mini PC"
    ];
  };
}
```

If Blueprint requires `nixpkgs.hostPlatform`, set it from the known host platform (home-lab is AMD64 Linux). Only add if check fails with a platform error:

```nix
nixpkgs.hostPlatform = "x86_64-linux";
```

- [ ] **Step 2: Rewrite `nix/hosts/test-bed/configuration.nix`**

```nix
{
  flake,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  networking = {
    hostName = "test-bed";
    networkmanager.enable = true;
  };

  programs.ssh.startAgent = true;

  services = {
    automatic-timezoned.enable = true;
    openssh.enable = true;
  };

  system.stateVersion = "25.05";
}
```

- [ ] **Step 3: Delete escape hatches and facade**

```bash
git rm nix/hosts/home-lab/default.nix nix/hosts/test-bed/default.nix nix/modules/nixos/default.nix
```

- [ ] **Step 4: Grep cleanup**

```bash
rg -n 'mylib|mylibFor|nixLib|class = "nixos"|nixosSystem|specialArgs|\.\./\.\./vars' nix/
```

Expected: no `mylib*` / escape hatch / path `../../vars`. Fix any leftover.

- [ ] **Step 5: Run check**

```bash
just check
```

Expected: pass. On failure, read the first error:

- missing `flake.modules.nixos.*` → confirm folder names and `default.nix` presence
- undefined `flake` → ensure host args include `flake` and barrels use fallback if needed
- module collision / double import → ensure only configuration.nix is host entry

- [ ] **Step 6: Optional eval smoke**

```bash
nix eval .#nixosConfigurations.home-lab.config.networking.hostName
nix eval .#nixosConfigurations.test-bed.config.networking.hostName
```

Expected: `"home-lab"` and `"test-bed"`.

- [ ] **Step 7: Commit**

```bash
git add nix/hosts nix/modules/nixos
git commit -m "$(cat <<'EOF'
refactor(hosts): switch to Blueprint-native configuration.nix

Delete nixosSystem escape hatches and nixosModules.default facade;
import shared stack via explicit flake.modules.nixos.*.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 7: Final verification and leftover hygiene

**Files:**

- Any remaining references fixed in-place

- [ ] **Step 1: Full grep**

```bash
rg -n 'mylib|mylibFor|nixLib|domain-builder|rclone-mounts\.nix|class = "nixos"|inputs\.self\.nixosModules\.default' nix/ || true
```

Expected: no hits for removed APIs.

- [ ] **Step 2: Final check**

```bash
just check
```

Expected: pass.

- [ ] **Step 3: Commit residual fixes if any; otherwise done**

If greps forced edits:

```bash
git add -A nix/
git commit -m "$(cat <<'EOF'
chore: remove leftover Blueprint simplify remnants

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

## Spec coverage checklist (author self-review)

| Spec requirement | Task |
|------------------|------|
| Discard broken WIP | Task 1 |
| Pure `flake.lib` auto-import + URLs | Task 2, Task 5 |
| Delete domain-builder dual form | Task 2 |
| `my.rclone.mounts` module | Task 3 |
| Migrate jellyfin/navidrome/desktop | Task 3 |
| Delete lib rclone helper | Task 3 |
| Move vars → modules/nixos/vars | Task 4 |
| Barrels without mylib | Task 5 |
| homepage URL via flake.lib | Task 5 (and temporary local in Task 2) |
| Native configuration.nix hosts | Task 6 |
| Delete host default.nix | Task 6 |
| Delete modules/nixos/default.nix | Task 6 |
| Explicit Approach 2 imports | Task 6 |
| `just check` green | Tasks 1–7 |
| No HM Phase 2 work | Not scheduled |

## Phase 2 reminder (do not implement here)

Blueprint Home Manager users under `hosts/<host>/users/` — separate plan + commits.
