# Forgejo Runner Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the home-lab NixOS host a working, declarative Forgejo Actions runner service, replacing the currently-broken in-progress module with one that generates its `config.yaml` via Nix builtins (`pkgs.formats.yaml`) and never puts the runner token in the Nix store.

**Architecture:** A reusable NixOS module at `nix/vars/forgejo-runner.nix` defines `options.services.forgejo-runner` (auto-imported globally by `nix/vars/default.nix`) and a single `systemd.services.forgejo-runner` unit. Each configured connection's non-secret fields (`url`, `uuid`, `labels`) are rendered straight into a build-time `config.yaml` via `pkgs.formats.yaml`. The secret token is never read by Nix or by our own code — it's handed to the unit via systemd's `LoadCredential=`, and the generated config references it with forgejo-runner's own `token_url: file:$CREDENTIALS_DIRECTORY/...` mechanism, which forgejo-runner resolves itself at process start. `nix/system-modules/services/forgejo-runner.nix` (this repo's per-host instantiation file, same role as every other file in that directory) just sets the home-lab connection's values.

**Tech Stack:** NixOS module system, `pkgs.formats.yaml`, systemd `LoadCredential=`, sops-nix (dotenv-format secret with per-key extraction), `forgejo-runner` (nixpkgs package).

## Global Constraints

- Use Nix builtins/standard library helpers for config generation wherever feasible — no hand-rolled shell templating for the YAML (superseded: `pkgs.formats.yaml` replaces the old `writeShellScript`-based approach).
- The runner token must never be copied into the Nix store (world-readable). Only the non-secret `uuid` may be a plain string in tracked Nix files — this mirrors Forgejo's own classification of UUID as "an identifier, not a secret" (see `https://forgejo.org/docs/latest/admin/actions/registration/`), while `token`/`token_url` stays secret.
- `nix/vars/*.nix` files are auto-imported globally by `nix/vars/default.nix` (`mylib.autoImportModules`) — a module placed there does **not** need to be separately `imports`-ed anywhere else.
- Verification command for every step in this plan: `just check` (= `nix flake check`), run from the repo root.
- Do not run `just deploy` / `nixos apply` — that applies to the live home-lab machine and is out of scope for this plan; the user runs it themselves when ready.

---

### Task 1: Reusable `services.forgejo-runner` module + home-lab wiring

**Files:**

- Modify: `nix/hosts/home-lab/modules/sops.nix:113-118` (the `sops.secrets.fjr-default` block)
- Modify: `nix/vars/forgejo-runner.nix` (currently an untracked, broken draft — full rewrite)
- Modify: `nix/system-modules/services/forgejo-runner.nix` (currently references a nonexistent `./forgejo-runner` import path — full rewrite)

**Interfaces:**

- Produces: `options.services.forgejo-runner.{enable,package,containerRuntime,connections,settings}` — consumed by `nix/system-modules/services/forgejo-runner.nix` and available globally to any future host.
- Produces: `config.sops.secrets.fjr-runner-token.path` — a runtime-only path (e.g. `/run/secrets/fjr-runner-token`) containing **only** the raw token string.
- Consumes: `config.networking.baseDomain` (already defined in `nix/vars/networking.nix`), `config.virtualisation.podman.enable` (already `true` via `nix/system-modules/features/podman.nix`).

- [ ] **Step 1: Replace the `fjr-default` sops secret with a token-only extraction**

Open `nix/hosts/home-lab/modules/sops.nix` and replace this block (around line 113):

```nix
  sops.secrets.fjr-default = {
    sopsFile = ../secrets/fjr-default.env;
    format = "dotenv";
    key = "";
    restartUnits = ["forgejo-runner-default.service"];
  };
```

with:

```nix
  sops.secrets.fjr-runner-token = {
    sopsFile = ../secrets/fjr-default.env;
    format = "dotenv";
    key = "TOKEN";
    restartUnits = ["forgejo-runner.service"];
  };
```

This reuses the same encrypted source file (`fjr-default.env`, which already has both `TOKEN=` and `UUID=` lines — confirmed by `git show HEAD:nix/hosts/home-lab/secrets/fjr-default.env`), but extracts only the `TOKEN` key into its own secret. No changes to the encrypted file itself are needed. Default sops-nix ownership (`root:root`, mode `0400`) is fine — the token is read via `LoadCredential=` in Task 1 Step 3, which systemd resolves before dropping to the service's dynamic user, so no `owner`/`group` override is required here (unlike the pattern used for `pangolin`/`hermes-env` etc.).

- [ ] **Step 2: Verify the secret evaluates**

Run: `nix eval .#nixosConfigurations.home-lab.config.sops.secrets.fjr-runner-token.path`
Expected: prints a string path such as `"/run/secrets/fjr-runner-token"` with no errors. (This does not decrypt anything — sops-nix only computes the target runtime path at eval time.)

- [ ] **Step 3: Write the reusable module**

Replace the entire contents of `nix/vars/forgejo-runner.nix` with:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.forgejo-runner;

  runtimeUnit =
    if cfg.containerRuntime == "podman"
    then "podman.socket"
    else "docker.service";

  runtimeGroup =
    if cfg.containerRuntime == "podman"
    then "podman"
    else "docker";

  yamlFormat = pkgs.formats.yaml {};

  connectionSettings =
    lib.mapAttrs (name: conn: {
      inherit (conn) url uuid labels;
      token_url = "file:$CREDENTIALS_DIRECTORY/token-${name}";
    })
    cfg.connections;

  mergedSettings = lib.recursiveUpdate cfg.settings {
    server.connections = connectionSettings;
  };

  configFile = yamlFormat.generate "forgejo-runner-config.yaml" mergedSettings;
in {
  options.services.forgejo-runner = {
    enable = lib.mkEnableOption "the Forgejo Actions runner daemon";

    package = lib.mkPackageOption pkgs "forgejo-runner" {};

    containerRuntime = lib.mkOption {
      type = lib.types.enum ["docker" "podman"];
      default = "podman";
      description = "OCI container runtime used to execute job containers.";
    };

    connections = lib.mkOption {
      default = {};
      description = ''
        Forgejo instances this runner polls for jobs. Each attribute name
        becomes a key under `server.connections` in the generated
        config.yaml (see `forgejo-runner generate-config`).
      '';
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.nonEmptyStr;
            description = "URL of the Forgejo instance.";
            example = "https://git.example.com";
          };

          uuid = lib.mkOption {
            type = lib.types.strMatching "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}";
            description = ''
              Runner UUID issued when the runner was registered in Forgejo.
              This is a public identifier, not a secret:
              https://forgejo.org/docs/latest/admin/actions/registration/
            '';
            example = "c9e50be9-a7c3-4aee-ba35-624c4ff8c519";
          };

          tokenFile = lib.mkOption {
            type = lib.types.nonEmptyStr;
            description = ''
              Path to a runtime-only file (e.g. a sops-nix secret path)
              containing just the runner token. Loaded via systemd's
              LoadCredential=, never copied into the Nix store.
            '';
            example = "/run/secrets/forgejo-runner-token";
          };

          labels = lib.mkOption {
            type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
            description = "Labels and execution environments advertised for this connection.";
            example = ["ubuntu-latest:docker://node:22-bookworm"];
          };
        };
      });
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = {};
      description = ''
        Extra forgejo-runner settings (log, runner, cache, host, container
        sections) merged into the generated config.yaml. See
        `forgejo-runner generate-config` for the full schema.
        `server.connections` is always overridden by
        `services.forgejo-runner.connections`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      [
        {
          assertion =
            if cfg.containerRuntime == "podman"
            then config.virtualisation.podman.enable
            else config.virtualisation.docker.enable;
          message = "services.forgejo-runner requires the ${cfg.containerRuntime} container runtime to be enabled.";
        }
      ]
      ++ lib.mapAttrsToList (name: _: {
        assertion = builtins.match "[A-Za-z0-9_-]+" name != null;
        message = "Forgejo runner connection name '${name}' must use only letters, numbers, underscores, or hyphens.";
      })
      cfg.connections;

    systemd.services.forgejo-runner = {
      description = "Forgejo Actions Runner";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target" runtimeUnit];
      after = ["network-online.target" runtimeUnit];

      environment =
        {HOME = "/var/lib/forgejo-runner";}
        // lib.optionalAttrs (cfg.containerRuntime == "podman") {
          DOCKER_HOST = "unix:///run/podman/podman.sock";
        };

      path = [pkgs.gitMinimal];

      serviceConfig = {
        DynamicUser = true;
        User = "forgejo-runner";
        SupplementaryGroups = [runtimeGroup];
        StateDirectory = "forgejo-runner";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/forgejo-runner";
        LoadCredential = lib.mapAttrsToList (name: conn: "token-${name}:${conn.tokenFile}") cfg.connections;
        ExecStart = "${lib.getExe cfg.package} daemon --config ${configFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
```

- [ ] **Step 4: Verify the module's options evaluate before it's wired to any host**

Run: `nix eval .#nixosConfigurations.home-lab.options.services.forgejo-runner.connections.type.description`
Expected: prints a description string (something like `"attribute set of (submodule)"`), no errors. This confirms `nix/vars/forgejo-runner.nix` is syntactically valid and merged in via the existing `nix/vars` auto-import — no separate `imports` line needed anywhere.

Run: `nix eval .#nixosConfigurations.home-lab.config.services.forgejo-runner.enable`
Expected: `false` (nothing enables it yet).

- [ ] **Step 5: Wire the home-lab connection**

Replace the entire contents of `nix/system-modules/services/forgejo-runner.nix` with:

```nix
{config, ...}: {
  services.forgejo-runner = {
    enable = true;
    containerRuntime = "podman";
    connections.default = {
      url = "https://git.${config.networking.baseDomain}";
      # CHANGE ME: replace with the real runner UUID (see Task 2, Step 1).
      uuid = "00000000-0000-0000-0000-000000000000";
      tokenFile = config.sops.secrets.fjr-runner-token.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
        "ubuntu-22.04:docker://node:22-bookworm"
      ];
    };
  };
}
```

The placeholder UUID is intentionally a syntactically valid dummy (matches the `uuid` option's regex) so the module evaluates cleanly now; Task 2 swaps in the real value. This follows the same placeholder-with-`# CHANGE ME` convention already used in `nix/vars/networking.nix`.

- [ ] **Step 6: Full flake check**

Run: `just check`
Expected: `nix flake check` passes with only the pre-existing Nextcloud warning (same baseline noted in `.agents/logs/2026-07-17.md`), no new errors.

- [ ] **Step 7: Inspect the generated config.yaml**

Run:

```bash
nix build .#nixosConfigurations.home-lab.config.system.build.toplevel --no-link --print-out-paths 2>&1 | tail -1
nix eval .#nixosConfigurations.home-lab.config.systemd.services.forgejo-runner.serviceConfig.ExecStart --raw
```

Take the `ExecStart` output, extract the `/nix/store/...-forgejo-runner-config.yaml` path after `--config`, and run:

```bash
cat /nix/store/...-forgejo-runner-config.yaml
```

Expected: a YAML document containing

```yaml
server:
  connections:
    default:
      url: https://git.<your-base-domain>
      uuid: 00000000-0000-0000-0000-000000000000
      labels:
        - ubuntu-latest:docker://node:22-bookworm
        - ubuntu-22.04:docker://node:22-bookworm
      token_url: file:$CREDENTIALS_DIRECTORY/token-default
```

No `token` field, and no literal token value anywhere in the store path.

- [ ] **Step 8: Commit**

```bash
git add nix/hosts/home-lab/modules/sops.nix nix/vars/forgejo-runner.nix nix/system-modules/services/forgejo-runner.nix
git commit -m "feat(services): rebuild forgejo-runner as a declarative module using pkgs.formats.yaml and LoadCredential"
```

---

### Task 2: Supply the real runner UUID and finish rollout

**Files:**

- Modify: `nix/system-modules/services/forgejo-runner.nix:8` (the placeholder `uuid` line)

**Interfaces:**

- Consumes: the `connections.default.uuid` option produced by Task 1.

- [ ] **Step 1: Retrieve the real UUID**

The runner is already registered (per `.agents/logs/2026-07-17.md`: "confirmed the live runner is registered, polling, and processing work"), so its UUID already exists in the encrypted secret. Decrypt just that field — this requires the machine's sops/age key, so run it yourself:

Run: `sops -d --extract '["UUID"]' nix/hosts/home-lab/secrets/fjr-default.env`
Expected: prints the runner's UUID, e.g. `c9e50be9-a7c3-4aee-ba35-624c4ff8c519`.

- [ ] **Step 2: Replace the placeholder**

In `nix/system-modules/services/forgejo-runner.nix`, replace:

```nix
      # CHANGE ME: replace with the real runner UUID (see Task 2, Step 1).
      uuid = "00000000-0000-0000-0000-000000000000";
```

with the real value from Step 1, e.g.:

```nix
      uuid = "c9e50be9-a7c3-4aee-ba35-624c4ff8c519";
```

- [ ] **Step 3: Final check**

Run: `just check`
Expected: passes with only the pre-existing Nextcloud warning.

- [ ] **Step 4: Commit**

```bash
git add nix/system-modules/services/forgejo-runner.nix
git commit -m "chore(services): set real forgejo-runner UUID"
```

- [ ] **Step 5: Hand off for deployment**

Do not run `just deploy` / `nixos apply` yourself — tell the user the change is ready and let them apply it to the live home-lab machine on their own schedule, since this replaces a currently-registered, in-use runner service.

---

## Self-Review

**Spec coverage:**

- "research how to write yaml configs in nix" → Task 1 uses `pkgs.formats.yaml`, the standard Nix mechanism, documented inline via the `settings` freeform option.
- "create a service configurator module in nix/vars/forgejo-runner.nix" → Task 1 Step 3.
- "create a service in nix/system-modules/services/forgejo-runner.nix" → Task 1 Step 5.
- "check how forgejo runner consumes config files" → researched via `forgejo-runner generate-config`, `daemon --help`, and Forgejo's registration docs; findings drove the `token_url`/`LoadCredential` design (see Global Constraints and Task 1's architecture note).
- "use nix builtins wherever feasible" → `pkgs.formats.yaml` replaces the previous `writeShellScript`-based runtime templating entirely; the only remaining "escape hatch" is the optional `settings` passthrough, which is the standard nixpkgs `services.*.settings` idiom.

**Placeholder scan:** The one placeholder (`uuid = "00000000-..."`) is a real, valid, working default annotated `# CHANGE ME`, matching the existing convention in `nix/vars/networking.nix` — not a plan gap, since Task 2 fully resolves it with an exact command and exact replacement text.

**Type consistency:** `connections`, `tokenFile`, `uuid`, `labels`, `containerRuntime` are named and typed identically between the options block (Task 1 Step 3) and their consumers (`connectionSettings`, `LoadCredential` mapping, and the host wiring in Step 5).
