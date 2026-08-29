# Chezmoi → Home Manager Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the portable parts of the chezmoi `files/` dotfile tree into shared Blueprint Home Manager modules, consumed by a new standalone `mr-fw16@fw16` config that works on Fedora now and by the existing NixOS `mr-nix` users later.

**Architecture:** Shared home modules under `nix/modules/home/` (exposed as `flake.modules.home.*`). `home.username` is de-hardcoded so the same modules serve `mr-fw16` (standalone) and `mr-nix` (NixOS). App config is nativized to Home Manager `programs.*` where a module exists; a verbatim long-tail goes through `xdg.configFile` / `home.file`. Packages land in `home.packages`, with a large GUI subset gated behind a new `mine.gui.enable` option. Two new flake inputs: `nixos-hardware` (for the future NixOS host) and `llm-agents` (for `herdr`/`rtk`/`apm`/`hermes-agent`, applied as an overlay so `pkgs.llm-agents.*` resolves).

**Tech Stack:** Nix flakes, numtide/blueprint, nix-community/home-manager, mcp-nixos (for option lookup), treefmt-nix, git-hooks.nix/prek.

**Spec:** `docs/superpowers/specs/2026-08-29-chezmoi-to-nix-migration-design.md`

**Source configs:** `~/.local/share/chezmoi/files/` (chezmoi root). Referenced per task by their chezmoi path (e.g. `dot_config/git/config`). The executor MUST read each named source file before porting it.

## Global Constraints

- `home.stateVersion` stays `"26.05"` (set once in `nix/modules/home/common.nix`); never redeclare it.
- Nix formatting: run `nix fmt` before every commit; `nix flake check` must stay green.
- Commit messages: Conventional Commits (`<type>(<scope>): <desc>`); valid scopes are in `cog.toml` (`scopes` array) — use `shell`, `hosts`, `hosts/home-lab`, `hosts/test-bed`, `flake`, `packages`, `git`, `zed`, `features`, or `nix`. Every AI-assisted commit ends with:
  `Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>`
  and `Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6`
- Every session appends to `.agents/logs/2026-08-29.md` (see AGENTS.md "MANDATORY: Action Logging").
- Blueprint arg style in `nix/` files: `{ flake, inputs, pkgs, lib, ... }`. Consume same-flake modules via `flake.modules.home.<name>` and `flake.modules.nixos.<name>`.
- New verbatim config files are vendored under `nix/modules/home/mr-nix/files/` — render any chezmoi templating ONCE (for `linux` / `fedora` / `laptop`) and commit the plain output; never commit `.tmpl` syntax.
- Do NOT migrate: Windows (`readonly_Documents/`, `powershell/`, `.chezmoiscripts/windows/`), `.chezmoiscripts/**`, `.chezmoidata/packages/linux/{arch,debian,ubuntu,fedora}.yaml`, `paru/`, chezmoi templating machinery, `antidot` runtime hooks, KDE/Plasma rc files, `MangoHud`, Flatpak lists, `marktext/`. (Spec §5.)
- `mcfly` is dropped. `mise` is kept. `soar` + `antidot` keep their config files only (binaries out-of-band).

---

## File structure

**New files:**

| Path                                       | Responsibility                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `nix/hosts/fw16/users/mr-fw16.nix`         | Standalone home stub: imports shared modules, sets identity + `mine.*` option values for the Framework 16 Fedora account   |
| `nix/modules/home/shell/session-vars.nix`  | `home.sessionVariables` + `home.sessionPath` (EDITOR, PAGER, CARGO_HOME, PATH extras)                                      |
| `nix/modules/home/shell/functions.nix`     | Shell functions ported from `shell_aliases.sh` (`line`, `rmedirs`, `touchfile`, `export-gh`, `export-glab`, `update-repo`) |
| `nix/modules/home/mr-nix/git.nix`          | `programs.git` full port + `options.mine.git.*`                                                                            |
| `nix/modules/home/mr-nix/zed.nix`          | `programs.zed-editor` (userSettings/userKeymaps/userTasks/extensions)                                                      |
| `nix/modules/home/mr-nix/dev-tools.nix`    | `programs.{lazygit,mise,direnv,gh,topgrade,gallery-dl,fastfetch}` + `tombi` verbatim                                       |
| `nix/modules/home/mr-nix/packages.nix`     | `home.packages` + `options.mine.gui.enable`                                                                                |
| `nix/modules/home/mr-nix/misc-configs.nix` | `xdg.configFile` / `home.file` verbatim long-tail                                                                          |
| `nix/modules/home/mr-nix/files/**`         | Vendored verbatim config payloads                                                                                          |

**Modified files:**

| Path                                  | Change                                                                      |
| ------------------------------------- | --------------------------------------------------------------------------- |
| `flake.nix`                           | add `nixos-hardware` + `llm-agents` inputs; apply `llm-agents` overlay      |
| `nix/modules/home/mr-nix/default.nix` | import new siblings; REMOVE `home.username`                                 |
| `nix/modules/home/shell/default.nix`  | import `./session-vars.nix` + `./functions.nix`                             |
| `nix/modules/home/shell/aliases.nix`  | merge in chezmoi aliases                                                    |
| `nix/modules/home/shell/zsh.nix`      | fold in `uv` / `cargo` completion init from `.zshrc.d`; de-dupe `touchfile` |
| `nix/hosts/home-lab/users/mr-nix.nix` | add `home.username = "mr-nix";`                                             |
| `nix/hosts/test-bed/users/mr-nix.nix` | add `home.username = "mr-nix";`                                             |

---

## How to test a Home Manager change (read once)

There are no unit tests. Each task is verified by building/inspecting the standalone config:

```bash
# Build the activation package for the new standalone config:
nix build --no-link --print-out-paths \
  '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage'

# Inspect a generated file inside the result (example: git config):
out=$(nix build --no-link --print-out-paths \
  '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
find "$out/home-files" -maxdepth 3 | sort
cat "$out/home-files/.config/git/config"

# Full gate (must stay green):
nix flake check
```

`nix eval` with `--apply` is blocked by the worktree guard in this environment — use `nix build` + `find`/`cat` on the result instead, or `nix flake show`.

---

## Task 1: Add flake inputs (nixos-hardware, llm-agents) + overlay

**Files:**

- Modify: `flake.nix`

**Interfaces:**

- Produces: `inputs.nixos-hardware`, `inputs.llm-agents`; `pkgs.llm-agents.<name>` resolvable in every module (via `nixpkgs.overlays`).

- [ ] **Step 1: Add the two inputs**

In `flake.nix`, inside `inputs = { … }`, add (keep the existing alphabetical ordering — `llm-agents` after `home-manager`… actually after `hermes-agent`; `nixos-hardware` after `nixos-cli`):

```nix
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
```

Do NOT add `inputs.nixpkgs.follows` to `llm-agents` — it ships its own pinned nixpkgs + binary cache; overriding it forces local rebuilds.

- [ ] **Step 2: Apply the llm-agents overlay in the Blueprint call**

Change the `outputs` block to:

```nix
  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [inputs.llm-agents.overlays.shared-nixpkgs];
      prefix = "nix";
      # nixpkgs 26.11 dropped x86_64-darwin; drop it from the generated
      # flake outputs so `nix flake check` / `nix flake show` stop erroring.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
```

- [ ] **Step 3: Lock the inputs**

Run: `nix flake lock`
Expected: `flake.lock` gains `llm-agents`, `nixos-hardware` (and their transitive deps).

- [ ] **Step 4: Verify the overlay resolves and nothing broke**

```bash
nix build --no-link '.#nixosConfigurations.home-lab.pkgs.llm-agents.herdr' 2>&1 | tail -5
nix flake check
```

Expected: the `herdr` derivation resolves (build may download from the numtide cache); `nix flake check` → `all checks passed!`.

If `overlays.shared-nixpkgs` does not exist (name changed upstream), run `nix flake show github:numtide/llm-agents.nix` and use the actual overlay attr; if there is no overlay, fall back to a module that sets
`nixpkgs.overlays = [(final: prev: { llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}; })]`
in a new `nix/modules/nixos/features/llm-agents-overlay.nix` AND an equivalent in home — but try the overlay output first.

- [ ] **Step 5: Commit**

```bash
nix fmt
git add flake.nix flake.lock
git commit -m "$(cat <<'EOF'
build(flake): add nixos-hardware and llm-agents inputs

llm-agents provides herdr/rtk/apm/hermes-agent (absent or newer than
nixpkgs); applied as the shared-nixpkgs overlay so pkgs.llm-agents.* works.
nixos-hardware is for the future NixOS fw16 host.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 2: De-hardcode `home.username`

**Files:**

- Modify: `nix/modules/home/mr-nix/default.nix`
- Modify: `nix/hosts/home-lab/users/mr-nix.nix`
- Modify: `nix/hosts/test-bed/users/mr-nix.nix`

**Interfaces:**

- Produces: `flake.modules.home.mr-nix` no longer sets `home.username`; consumers own identity. Blueprint sets `home.username = lib.mkDefault "<path-name>"` automatically, so NixOS stubs only need an explicit value if they must override the path (they don't — path is already `mr-nix`), but set it explicitly for clarity and to survive a future rename.

- [ ] **Step 1: Read the current files**

Read `nix/modules/home/mr-nix/default.nix`, `nix/hosts/home-lab/users/mr-nix.nix`, `nix/hosts/test-bed/users/mr-nix.nix`.

- [ ] **Step 2: Remove `home.username` from the shared module**

`nix/modules/home/mr-nix/default.nix` becomes (imports list will grow in later tasks — leave the existing `./keepassxc.nix`):

```nix
{...}: {
  # Shared per-user Home Manager config for the interactive account.
  # Identity (home.username / home.homeDirectory) is owned by the consumer
  # stub under hosts/<host>/users/, so the same module serves both the
  # NixOS `mr-nix` user and the standalone Fedora `mr-fw16` account.
  imports = [
    ./keepassxc.nix
  ];
}
```

- [ ] **Step 3: Set username in the NixOS stubs**

Both `nix/hosts/home-lab/users/mr-nix.nix` and `nix/hosts/test-bed/users/mr-nix.nix` — add `home.username = "mr-nix";` alongside the existing imports:

```nix
{inputs, ...}: {
  imports = [
    inputs.self.homeModules.common
    inputs.self.homeModules.mr-nix
  ];
  home.username = "mr-nix";
}
```

- [ ] **Step 4: Verify existing configs still evaluate**

```bash
nix flake check
nix build --no-link '.#legacyPackages.x86_64-linux.homeConfigurations."mr-nix@home-lab".activationPackage' 2>&1 | tail -5
```

Expected: green; `mr-nix@home-lab` builds.

- [ ] **Step 5: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/default.nix nix/hosts/home-lab/users/mr-nix.nix nix/hosts/test-bed/users/mr-nix.nix
git commit -m "$(cat <<'EOF'
refactor(hosts): move home.username from shared module to user stubs

Lets homeModules.mr-nix serve both the NixOS mr-nix user and a standalone
non-mr-nix account.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 3: Create the `fw16` standalone stub

**Files:**

- Create: `nix/hosts/fw16/users/mr-fw16.nix`

**Interfaces:**

- Consumes: `flake.modules.home.common`, `flake.modules.home.mr-nix`.
- Produces: `legacyPackages.<system>.homeConfigurations."mr-fw16@fw16"`. Sets `mine.git.*` and `mine.gui.enable` (options defined in Tasks 5 & 8 — until then this stub sets values for options that don't exist yet, so add the `mine.*` attrs only in the task that introduces each option; for THIS task the stub is minimal).

- [ ] **Step 1: Create the minimal stub**

`nix/hosts/fw16/users/mr-fw16.nix`:

```nix
{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.self.homeModules.common
    inputs.self.homeModules.mr-nix
  ];

  # Real Fedora login on the Framework 16 (not "mr-nix").
  home.username = "mr-fw16";
  home.homeDirectory = "/home/mr-fw16";

  # Home Manager running on Fedora, not NixOS.
  targets.genericLinux.enable = true;
}
```

- [ ] **Step 2: Verify the standalone config is generated and builds**

```bash
nix flake show 2>&1 | grep -A3 homeConfigurations
nix build --no-link --print-out-paths \
  '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage'
```

Expected: `mr-fw16@fw16` listed; activation package builds.

- [ ] **Step 3: Verify `nix flake check`**

Run: `nix flake check`
Expected: `all checks passed!`

- [ ] **Step 4: Commit**

```bash
nix fmt
git add nix/hosts/fw16/users/mr-fw16.nix
git commit -m "$(cat <<'EOF'
feat(hosts): add standalone fw16 home config for mr-fw16

Blueprint generates homeConfigurations."mr-fw16@fw16" from this stub;
runs Home Manager standalone on the Fedora Framework 16.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 4: Shell — session vars, functions, aliases, completions

**Files:**

- Create: `nix/modules/home/shell/session-vars.nix`
- Create: `nix/modules/home/shell/functions.nix`
- Modify: `nix/modules/home/shell/default.nix`
- Modify: `nix/modules/home/shell/aliases.nix`
- Modify: `nix/modules/home/shell/zsh.nix`

**Interfaces:**

- Consumes: existing `programs.zsh` (from `zsh.nix`), `programs.eza` Zsh integration (provides `ls`/`ll`/`la`).
- Produces: `home.sessionVariables.{EDITOR,VISUAL,PAGER,CARGO_HOME}`, `home.sessionPath`, and zsh functions `line`, `rmedirs`, `touchfile`, `export-gh`, `export-glab`, `update-repo`.

- [ ] **Step 1: Read the chezmoi sources**

Read: `~/.local/share/chezmoi/files/.chezmoitemplates/shell-scripts/00-export_paths.sh`, `~/.local/share/chezmoi/files/.chezmoitemplates/shell-scripts/shell_aliases.sh`, `~/.local/share/chezmoi/files/.chezmoitemplates/shell-scripts/11-uv.sh`, `~/.local/share/chezmoi/files/.chezmoitemplates/shell-scripts/13-cargo.sh`, and current `nix/modules/home/shell/zsh.nix` (note it already defines `touchfile` in `initContent`).

- [ ] **Step 2: Create `session-vars.nix`**

```nix
# Session env + PATH. XDG base dirs are set by Home Manager itself; do not
# re-export them. SELINUX_MODE / antidot / mise-shim PATH from the chezmoi
# 00-export_paths.sh are intentionally dropped (declarative env; mise shims
# come from programs.mise's zsh integration).
{
  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    PAGER = "less";
    CARGO_HOME = "${config.home.homeDirectory}/.local/share/cargo";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/cargo/bin"
    "$HOME/.local/share/soar/bin"
  ];
}
```

Fix the module header to take `config`:

```nix
{config, ...}: {
  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    PAGER = "less";
    CARGO_HOME = "${config.home.homeDirectory}/.local/share/cargo";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/cargo/bin"
    "$HOME/.local/share/soar/bin"
  ];
}
```

- [ ] **Step 3: Create `functions.nix`**

Port the functions verbatim from `shell_aliases.sh` (read it first — reproduce the bodies exactly). Put them in `programs.zsh.initContent` at a normal order:

```nix
{lib, ...}: {
  programs.zsh.initContent = lib.mkOrder 600 ''
    line() {
      printf '%*s\n' "''${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
    }

    rmedirs() {
      local dir="''${1:-.}"
      local answer
      if [[ ! -d "''${dir}" ]]; then
        echo "Error: '''${dir}' is not a valid directory."
        return 1
      fi
      echo "Dry run: empty directories that would be removed:"
      line
      find "''${dir}" -mindepth 1 -depth -type d -empty -print
      line
      printf "Remove these empty directories? [y/N]: "
      read -r answer
      case "''${answer}" in
        [yY] | [yY][eE][sS])
          echo "Deleting..."
          find "''${dir}" -mindepth 1 -depth -type d -empty -delete
          echo "Done."
          ;;
        *) echo "Aborted." ;;
      esac
    }

    touchfile() {
      mkdir -p "$(dirname "$1")" && touch "$1" && echo "$1"
    }

    export-gh() {
      local token
      command -v gh >/dev/null 2>&1 || { echo "Error: 'gh' is not installed." >&2; return 1; }
      token="$(gh auth token)" || { echo "Error: failed to get GitHub token." >&2; return 1; }
      export GITHUB_TOKEN="''${token}"
      echo "GITHUB_TOKEN exported."
    }

  '';
}
```

`export-glab` — port verbatim from `shell_aliases.sh` into the same `initContent` block (it parses the token from `glab auth status --show-token` with `sed`, then `export GITLAB_TOKEN`). Escape `$` as `''$` inside the Nix string.

For `update-repo` (long, ~60 lines in `shell_aliases.sh`): reproduce it in the same `initContent` block verbatim from the source — escape `${` as `''${` and `''` (empty) is not present. Read `shell_aliases.sh` and copy the whole `update-repo() { … }` body.

- [ ] **Step 4: Remove the duplicate `touchfile` from `zsh.nix`**

In `nix/modules/home/shell/zsh.nix` `initContent`, delete the line:
`touchfile() { mkdir -p "$(dirname "$1")" && touch "$1" && echo "$1"; }`
(now owned by `functions.nix`).

- [ ] **Step 5: Add uv / cargo completions to `zsh.nix`**

Append to the `zsh.nix` `initContent` (the `lib.mkOrder 550` block), after the existing content:

```nix
        # uv / uvx completions (chezmoi .zshrc.d/11-uv.sh)
        if (( ''${+commands[uv]} )); then
          eval "$(uv --generate-shell-completion zsh)"
          eval "$(uvx --generate-shell-completion zsh)"
        fi
        # cargo completion via rustup's fpath function (chezmoi .zshrc.d/13-cargo.sh)
        if (( ''${+commands[rustc]} )); then
          _rust_zsh_fns="$(rustc --print sysroot)/share/zsh/site-functions"
          if [[ -d "''${_rust_zsh_fns}" ]]; then
            fpath=("''${_rust_zsh_fns}" ''${fpath})
            autoload -Uz _cargo
          fi
          unset _rust_zsh_fns
        fi
```

- [ ] **Step 6: Merge chezmoi aliases into `aliases.nix`**

Read current `nix/modules/home/shell/aliases.nix` (already has `cat`, `tb`, `tf`, `grep` etc.). Add the missing ones from `shell_aliases.sh` that make sense on NixOS/Fedora:

```nix
{
  home.shellAliases = {
    cat = "bat --paging=never";
    dir = "dir --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
    grep = "grep --color=auto";
    tb = "nc termbin.com 9999";
    tf = "touchfile";
    vdir = "vdir --color=auto";
    # from chezmoi shell_aliases.sh
    bunx = "bun x";
    l = "ls -CF";
    la = "ls -A";
    ll = "ls -alF";
  };
}
```

Do NOT add `dnf = "dnf5"` (Fedora-only; irrelevant and confusing on NixOS) or `zed = "zeditor"` (handle Zed via `programs.zed-editor` + PATH). If `programs.eza` already supplies `ll`/`la`/`l` and a collision warning appears, drop those three here.

- [ ] **Step 7: Wire the new modules**

`nix/modules/home/shell/default.nix` — add to `imports`:

```nix
    ./functions.nix
    ./session-vars.nix
```

- [ ] **Step 8: Build and inspect**

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
grep -R "export-glab\|rmedirs\|GITHUB_TOKEN" "$out/home-files/.zshrc" || cat "$out/home-files/.config/zsh/.zshrc"
grep -R "EDITOR" "$out/home-path" -l 2>/dev/null; cat "$out/home-files/.config/environment.d/"*.conf 2>/dev/null || true
nix flake check
```

Expected: functions present in the generated zshrc; `nix flake check` green. (Session vars land in `~/.config/environment.d` and/or the zsh env; exact path varies — confirm they're set with `home-manager` docs if unsure.)

- [ ] **Step 9: Commit**

```bash
nix fmt
git add nix/modules/home/shell/
git commit -m "$(cat <<'EOF'
feat(shell): port chezmoi shell env, functions and aliases to Home Manager

session-vars.nix (EDITOR/PAGER/CARGO_HOME + PATH), functions.nix
(line/rmedirs/touchfile/export-gh/export-glab/update-repo), uv+cargo
completions folded into zsh.nix, aliases merged. mcfly/antidot dropped.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 5: `programs.git` port + `mine.git` option

**Files:**

- Create: `nix/modules/home/mr-nix/git.nix`
- Create: `nix/modules/home/mr-nix/files/git/templates/hooks/commit-msg`
- Create: `nix/modules/home/mr-nix/files/git/templates/hooks/pre-commit`
- Modify: `nix/modules/home/mr-nix/default.nix` (import `./git.nix`)
- Modify: `nix/hosts/fw16/users/mr-fw16.nix` (set `mine.git.*`)

**Interfaces:**

- Produces: `options.mine.git.{userName,userEmail,signingKey}` (all `lib.types.str`). Consumed by the fw16 stub. `programs.git.enable = true` with delta, credential helpers, `includeIf` blocks, signing.

- [ ] **Step 1: Read the source**

Read `~/.local/share/chezmoi/files/dot_config/git/config`, `~/.local/share/chezmoi/files/dot_config/git/templates/hooks/executable_commit-msg`, `~/.local/share/chezmoi/files/dot_config/git/templates/hooks/executable_pre-commit`.

- [ ] **Step 2: Vendor the hook scripts**

Copy the two hook scripts verbatim into `nix/modules/home/mr-nix/files/git/templates/hooks/{commit-msg,pre-commit}` (strip the `executable_` chezmoi prefix).

- [ ] **Step 3: Write `git.nix`**

```nix
{
  lib,
  config,
  ...
}: let
  cfg = config.mine.git;
in {
  options.mine.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      description = "git user.name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "git user.email";
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
      description = "GPG signing key id/fingerprint for commit.gpgsign.";
    };
  };

  config.programs.git = {
    enable = true;
    userName = cfg.userName;
    userEmail = cfg.userEmail;

    delta = {
      enable = true;
      options = {
        line-numbers = true;
        navigate = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
    };

    signing = {
      key = cfg.signingKey;
      signByDefault = true;
    };

    aliases = {}; # chezmoi git config defines no [alias] section

    includes = [
      {
        condition = "hasconfig:remote.*.url:https://gitlab.com/axisnexa/**";
        path = "~/.config/git/config-axisnexa";
      }
      {
        condition = "gitdir/i:**/AxisNexa/";
        path = "~/.config/git/config-axisnexa";
      }
      {
        condition = "gitdir/i:**/UniMelb/";
        path = "~/.config/git/config-unimelb";
      }
    ];

    extraConfig = {
      init = {
        defaultBranch = "main";
        templateDir = "~/.config/git/templates";
      };
      core.editor = "zed -n --wait";
      merge = {
        ff = "only";
        guitool = "meld";
      };
      tag = {
        forceSignAnnotated = true;
        gpgsign = true;
      };
      push.followTags = true;
      log.showSignature = true;
      interactive.diffFilter = "delta --color-only";
      credential = {
        helper = ["cache --timeout 21600" "libsecret" "oauth"];
        "https://github.com".helper = "!gh auth git-credential";
        "https://gist.github.com".helper = "!gh auth git-credential";
        "https://gitlab.com".helper = "!glab auth git-credential";
      };
    };
  };

  # git hook templates referenced by init.templateDir
  config.home.file = {
    ".config/git/templates/hooks/commit-msg" = {
      source = ./files/git/templates/hooks/commit-msg;
      executable = true;
    };
    ".config/git/templates/hooks/pre-commit" = {
      source = ./files/git/templates/hooks/pre-commit;
      executable = true;
    };
  };
}
```

Notes for the executor:

- chezmoi's `core.pager = "/usr/bin/delta …"` and delta-as-pager are replaced by `programs.git.delta` (Home Manager wires `core.pager`/`interactive.diffFilter`). Do not set `core.pager` manually.
- `config-axisnexa` / `config-unimelb` are NOT in the chezmoi tree — the `includeIf` entries simply no-op when the files are absent. Leave them unmanaged.
- If `programs.git.delta` errors on an unknown option key, move that key into `extraConfig.delta.<key>`.

- [ ] **Step 4: Import + set values**

`nix/modules/home/mr-nix/default.nix` imports: add `./git.nix`.

`nix/hosts/fw16/users/mr-fw16.nix` — add:

```nix
  mine.git = {
    userName = "MRDGH2821";
    userEmail = "ask.mrdgh2821@outlook.com";
    # Value from chezmoi dot_config/git/config -> [user].signingkey
    signingKey = "<gpg-signing-key-id>";
  };
```

(NixOS `mr-nix` stubs will fail to eval now because `mine.git` has no values — set placeholders there too, or make the options have `default = ""`. Choose: give `userName`/`userEmail`/`signingKey` `default = ""` so only fw16 needs real values, and add `lib.mkIf (cfg.signingKey != "")` around `signing`. Simpler: set the same three values in the home-lab/test-bed stubs. Pick the `default = ""` + `mkIf` route to avoid duplicating identity in three files.)

Revised option block:

```nix
  options.mine.git = {
    userName = lib.mkOption { type = lib.types.str; default = ""; };
    userEmail = lib.mkOption { type = lib.types.str; default = ""; };
    signingKey = lib.mkOption { type = lib.types.str; default = ""; };
  };
  config.programs.git = {
    enable = true;
    userName = lib.mkIf (cfg.userName != "") cfg.userName;
    userEmail = lib.mkIf (cfg.userEmail != "") cfg.userEmail;
    signing = lib.mkIf (cfg.signingKey != "") {
      key = cfg.signingKey;
      signByDefault = true;
    };
    # … rest unconditional …
  };
```

- [ ] **Step 5: Build + inspect the generated git config**

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
cat "$out/home-files/.config/git/config"
test -x "$out/home-files/.config/git/templates/hooks/pre-commit" && echo "hook executable OK"
nix flake check
```

Expected: config has `[user] name/email`, `[commit] gpgsign = true`, `[user] signingkey`, delta blocks, `[includeIf …]`, credential helper stack; hooks executable; `nix flake check` green.

- [ ] **Step 6: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/git.nix nix/modules/home/mr-nix/files/git nix/modules/home/mr-nix/default.nix nix/hosts/fw16/users/mr-fw16.nix
git commit -m "$(cat <<'EOF'
feat(git): port chezmoi git config to programs.git

Delta, includeIf work/uni splits, gh/glab/libsecret/oauth credential
helper stack, GPG signing. Identity + signing key via new mine.git.*
option, set per stub.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 6: `programs.zed-editor` port

**Files:**

- Create: `nix/modules/home/mr-nix/zed.nix`
- Modify: `nix/modules/home/mr-nix/default.nix` (import `./zed.nix`)

**Interfaces:**

- Consumes: nothing new.
- Produces: `programs.zed-editor` with `userSettings`, `userKeymaps`, `userTasks`, `extensions`; `package = null` (config-only; Zed installed by the OS / GUI layer).

- [ ] **Step 1: Read the source**

Read `~/.local/share/chezmoi/files/dot_config/zed/private_settings.json`, `~/.local/share/chezmoi/files/dot_config/zed/keymap.json`, `~/.local/share/chezmoi/files/dot_config/zed/tasks.json`.

- [ ] **Step 2: Write `zed.nix`**

Translate the three JSON files into Nix attrs / lists. `userSettings` is the object from `private_settings.json`; `userKeymaps` is the array from `keymap.json`; `userTasks` is the array from `tasks.json`; `extensions` is the list of keys in `auto_install_extensions` whose value is `true`.

```nix
{...}: {
  programs.zed-editor = {
    enable = true;
    package = null; # config only; Zed comes from the OS / GUI package layer

    extensions = [
      "basher"
      "cargo-appraiser"
      "colored-zed-icons-theme"
      "cspell"
      "docker-compose"
      "dockerfile"
      "editorconfig"
      "env"
      "git-firefly"
      "gotmpl"
      "ini"
      "json5"
      "just"
      "log"
      "nix"
      "path-server-lsp"
      "powershell"
      "rumdl"
      "ssh-config"
      "tombi"
      "toml"
      "typos"
      "typst"
      "xml"
    ];

    userSettings = {
      # … full object from private_settings.json, as Nix attrs …
    };

    userKeymaps = [
      # … full array from keymap.json …
    ];

    userTasks = [
      # … full array from tasks.json …
    ];
  };
}
```

Executor: transcribe the JSON exactly. JSON `true`/`false`/numbers/strings map directly; JSON objects → `{ }`, arrays → `[ ]`. Keep `context_servers.mcp-nixos`, `agent.*`, `telemetry.*` as-is. `mutableUserSettings` / `mutableUserKeymaps` / `mutableUserTasks` are left at their defaults (`false`) — declarative.

- [ ] **Step 3: Import**

`nix/modules/home/mr-nix/default.nix` imports: add `./zed.nix`.

- [ ] **Step 4: Build + inspect**

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
python3 -m json.tool "$out/home-files/.config/zed/settings.json" >/dev/null && echo "settings.json valid"
python3 -m json.tool "$out/home-files/.config/zed/keymap.json" >/dev/null && echo "keymap.json valid"
python3 -m json.tool "$out/home-files/.config/zed/tasks.json" >/dev/null && echo "tasks.json valid"
nix flake check
```

Expected: three valid JSON files generated; `nix flake check` green.

- [ ] **Step 5: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/zed.nix nix/modules/home/mr-nix/default.nix
git commit -m "$(cat <<'EOF'
feat(zed): port chezmoi Zed settings/keymap/tasks to programs.zed-editor

Config only (package = null); extensions auto-installed. Declarative
userSettings/userKeymaps/userTasks.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 7: `dev-tools.nix` — lazygit, mise, direnv, gh, topgrade, gallery-dl, fastfetch

**Files:**

- Create: `nix/modules/home/mr-nix/dev-tools.nix`
- Create: `nix/modules/home/mr-nix/files/tombi.toml`
- Modify: `nix/modules/home/mr-nix/default.nix` (import `./dev-tools.nix`)

**Interfaces:**

- Produces: `programs.{lazygit,mise,direnv,gh,topgrade,gallery-dl,fastfetch}` enabled + configured; `xdg.configFile."tombi/config.toml"`.

- [ ] **Step 1: Read the sources**

Read `~/.local/share/chezmoi/files/dot_config/lazygit/config.yml`, `dot_config/mise/config.toml`, `dot_config/topgrade.toml`, `dot_config/gallery-dl/config.json`, `dot_config/fastfetch/config.jsonc`, `dot_config/tombi/config.toml`.

- [ ] **Step 2: Vendor tombi config**

Copy `dot_config/tombi/config.toml` verbatim → `nix/modules/home/mr-nix/files/tombi.toml`.

- [ ] **Step 3: Write `dev-tools.nix`**

```nix
{...}: {
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        overrideGpg = true;
        merging.manualCommit = true;
        diffRenderers = [
          {
            colorArg = "always";
            command = ''delta --dark --side-by-side --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
          }
        ];
      };
      gui.sidePanelWidth = 0.3;
      os.editPreset = "zed";
    };
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableMutableConfig = true; # user still runs `mise use`
    globalConfig.tools = {
      # transcribe [tools] from dot_config/mise/config.toml verbatim
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };

  programs.topgrade = {
    enable = true;
    settings = {
      # transcribe dot_config/topgrade.toml verbatim
    };
  };

  programs.gallery-dl = {
    enable = true;
    settings = {
      # transcribe dot_config/gallery-dl/config.json verbatim
    };
  };

  programs.fastfetch = {
    enable = true;
    settings = {
      # transcribe dot_config/fastfetch/config.jsonc — strip // comments.
      # DROP modules with hardcoded foreign paths:
      #  - the "command" weather module (/home/arch/.config/fastfetch/weather.sh)
      #  - the "/mnt/ISOz" disk entry
      # Keep everything else.
    };
  };

  xdg.configFile."tombi/config.toml".source = ./files/tombi.toml;
}
```

Executor: `lazygit.settings` is YAML→attrs, `mise.globalConfig`/`topgrade.settings` are TOML→attrs, `gallery-dl.settings`/`fastfetch.settings` are JSON→attrs. Mise tool keys with colons (`"aqua:cantino/mcfly"`) stay quoted strings. Note the mise list includes `mcfly` as an aqua tool — KEEP it (dropping mcfly refers to the shell-history integration, not blocking the binary if the user pins it via mise; but the `programs.mcfly` HM module is NOT used).

- [ ] **Step 4: Import + build + inspect**

`nix/modules/home/mr-nix/default.nix` imports: add `./dev-tools.nix`.

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
cat "$out/home-files/.config/lazygit/config.yml"
cat "$out/home-files/.config/mise/config.toml" 2>/dev/null || echo "(mutable mise config — check conf.d/)"
python3 -m json.tool "$out/home-files/.config/fastfetch/config.jsonc" >/dev/null && echo "fastfetch json OK"
nix flake check
```

Expected: all config files generated; `nix flake check` green.

- [ ] **Step 5: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/dev-tools.nix nix/modules/home/mr-nix/files/tombi.toml nix/modules/home/mr-nix/default.nix
git commit -m "$(cat <<'EOF'
feat(features): port dev-tool configs to Home Manager

lazygit, mise (globalConfig), direnv+nix-direnv, gh, topgrade,
gallery-dl, fastfetch (foreign-path modules dropped), tombi verbatim.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 8: `packages.nix` — `home.packages` + `mine.gui.enable`

**Files:**

- Create: `nix/modules/home/mr-nix/packages.nix`
- Modify: `nix/modules/home/mr-nix/default.nix` (import `./packages.nix`)
- Modify: `nix/hosts/fw16/users/mr-fw16.nix` (`mine.gui.enable = true`)

**Interfaces:**

- Produces: `options.mine.gui.enable` (`lib.types.bool`, `default = false`). `home.packages` = CLI set always + GUI set when `mine.gui.enable`.

- [ ] **Step 1: Read the sources**

Read `~/.local/share/chezmoi/files/.chezmoidata/packages/linux/linux_common.yaml`, `.chezmoidata/packages/linux/fedora.yaml`, `.chezmoidata/packages/rust.yaml`, `dot_config/mise/config.toml`.

- [ ] **Step 2: Resolve each package name in nixpkgs**

For every candidate, confirm the nixpkgs attribute with mcp-nixos (`nix {"action":"search","query":"<name>"}`), because names drift (`nvtop` → `nvtopPackages.full`, `tealdeer` provides `tldr`, etc.). Build a "resolved" list and a "not in nixpkgs" list. The spec §3.6 has the starting sets.

- [ ] **Step 3: Write `packages.nix`**

```nix
{
  lib,
  pkgs,
  config,
  ...
}: {
  options.mine.gui.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Install GUI applications (desktop hosts only).";
  };

  config.home.packages = with pkgs;
    [
      # CLI / dev — always
      bat
      fd
      ripgrep
      fzf
      zoxide
      direnv
      gh
      glab
      lazygit
      git-cliff
      cocogitto
      copier
      cspell
      fastfetch
      nodejs
      bun
      uv
      yq-go
      jq
      prek
      typos
      shfmt
      shellcheck
      ls-lint
      keep-sorted
      rumdl
      tombi
      typstyle
      typst
      repgrep
      topgrade
      oh-my-posh
      btop
      tmux
      sccache
      rustup
      git-credential-oauth
      tealdeer
      nvtopPackages.full
      syncthing
      cargo-edit
      cargo-update
      prettypst
      # from llm-agents overlay
      llm-agents.herdr
      llm-agents.rtk
      llm-agents.apm
      llm-agents.hermes-agent
    ]
    ++ lib.optionals config.mine.gui.enable [
      firefox
      keepassxc
      kdePackages.kleopatra
      vlc
      meld
      discord
      obs-studio
      heroic
      marktext
      sourcegit
    ];
}
```

Executor: adjust attribute paths per Step 2 findings. For any package that fails to build or is absent, move it to a `# not available: …` comment block and note it in the task's commit body — do NOT block the whole module on one package. `alejandra`/`treefmt` are provided by the flake devshell — do not add them here. `podman`/`nix` are system-level — not here.

- [ ] **Step 4: Import + enable GUI on fw16**

`nix/modules/home/mr-nix/default.nix` imports: add `./packages.nix`.

`nix/hosts/fw16/users/mr-fw16.nix` — add `mine.gui.enable = true;`.

- [ ] **Step 5: Build + inspect**

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
ls "$out/home-path/bin" | sort | head -50
ls "$out/home-path/bin" | grep -E '^(herdr|rtk|rg|bat|lazygit|firefox)$'
nix flake check
```

Expected: binaries present incl. `herdr`/`rtk` (llm-agents) and `firefox` (GUI); `nix flake check` green.

- [ ] **Step 6: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/packages.nix nix/modules/home/mr-nix/default.nix nix/hosts/fw16/users/mr-fw16.nix
git commit -m "$(cat <<'EOF'
feat(packages): port chezmoi package set to home.packages

CLI/dev tools always; GUI apps (firefox, keepassxc, obs, heroic, …)
behind new mine.gui.enable (on for fw16). herdr/rtk/apm/hermes from the
llm-agents overlay. Non-nixpkgs packages noted in-file.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 9: `misc-configs.nix` — verbatim long-tail

**Files:**

- Create: `nix/modules/home/mr-nix/misc-configs.nix`
- Create: `nix/modules/home/mr-nix/files/{herdr.toml,soar-config.toml,soar-packages.toml,opencode.json,opencode-tui.json,cargo-config.toml,nix.conf,copier-settings.yml,shellcheckrc}`
- Create: `nix/modules/home/mr-nix/files/bin/{cspell-refresh-words,herdr-open}`
- Modify: `nix/modules/home/mr-nix/default.nix` (import `./misc-configs.nix`)

**Interfaces:**

- Produces: `xdg.configFile` entries for herdr, soar, opencode, copier, nix; `home.file` for `~/.shellcheckrc`, `~/.local/share/cargo/config.toml`, and two `~/.local/bin` executables.

- [ ] **Step 1: Read + vendor the sources**

Read and copy verbatim (strip chezmoi `executable_` / `dot_` prefixes; these files have no templating):

| chezmoi source                                  | vendored as                      |
| ----------------------------------------------- | -------------------------------- |
| `dot_config/herdr/config.toml`                  | `files/herdr.toml`               |
| `dot_config/soar/config.toml`                   | `files/soar-config.toml`         |
| `dot_config/soar/packages.toml`                 | `files/soar-packages.toml`       |
| `dot_config/opencode/opencode.json`             | `files/opencode.json`            |
| `dot_config/opencode/tui.json`                  | `files/opencode-tui.json`        |
| `dot_local/share/cargo/config.toml`             | `files/cargo-config.toml`        |
| `dot_config/nix/nix.conf`                       | `files/nix.conf`                 |
| `dot_config/copier/settings.yml`                | `files/copier-settings.yml`      |
| `dot_shellcheckrc`                              | `files/shellcheckrc`             |
| `dot_local/bin/executable_cspell-refresh-words` | `files/bin/cspell-refresh-words` |
| `dot_local/bin/executable_herdr-open`           | `files/bin/herdr-open`           |

- [ ] **Step 2: Write `misc-configs.nix`**

```nix
{...}: {
  xdg.configFile = {
    "herdr/config.toml".source = ./files/herdr.toml;
    "soar/config.toml".source = ./files/soar-config.toml;
    "soar/packages.toml".source = ./files/soar-packages.toml;
    "opencode/opencode.json".source = ./files/opencode.json;
    "opencode/tui.json".source = ./files/opencode-tui.json;
    "copier/settings.yml".source = ./files/copier-settings.yml;
    "nix/nix.conf".source = ./files/nix.conf;
  };

  home.file = {
    ".shellcheckrc".source = ./files/shellcheckrc;
    ".local/share/cargo/config.toml".source = ./files/cargo-config.toml;
    ".local/bin/cspell-refresh-words" = {
      source = ./files/bin/cspell-refresh-words;
      executable = true;
    };
    ".local/bin/herdr-open" = {
      source = ./files/bin/herdr-open;
      executable = true;
    };
  };
}
```

Notes:

- On the standalone Fedora config `nix/nix.conf` is a user override — harmless. If a later NixOS `fw16` host adopts these modules, guard this one entry with `lib.mkIf (!config.targets.genericLinux.enable)` or move it to the NixOS layer. For now leave it.
- The `cargo-config.toml` sets `rustc-wrapper = "sccache"` — `sccache` is in `home.packages` (Task 8). Fine.

- [ ] **Step 3: Import + build + inspect**

`nix/modules/home/mr-nix/default.nix` imports: add `./misc-configs.nix`.

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
find "$out/home-files/.config" -maxdepth 2 -name '*.toml' -o -name '*.json' | sort
test -x "$out/home-files/.local/bin/herdr-open" && echo "herdr-open executable OK"
nix flake check
```

Expected: all files present; scripts executable; `nix flake check` green.

- [ ] **Step 4: Commit**

```bash
nix fmt
git add nix/modules/home/mr-nix/misc-configs.nix nix/modules/home/mr-nix/files nix/modules/home/mr-nix/default.nix
git commit -m "$(cat <<'EOF'
feat(features): vendor verbatim configs (herdr, soar, opencode, …)

xdg.configFile / home.file drop-ins for the long tail with no Home
Manager module: herdr, soar, opencode, copier, nix.conf, shellcheckrc,
cargo sccache wrapper, and the two ~/.local/bin helper scripts.

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

---

## Task 10: Final verification + close-out

**Files:**

- Modify: `.agents/logs/2026-08-29.md`
- Modify: `docs/superpowers/specs/2026-08-29-chezmoi-to-nix-migration-design.md` (append "Implemented" note + link this plan) — optional

- [ ] **Step 1: Full gate**

```bash
nix fmt
nix flake check
nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage'
nix build --no-link '.#legacyPackages.x86_64-linux.homeConfigurations."mr-nix@home-lab".activationPackage' 2>&1 | tail -3
nix build --no-link '.#nixosConfigurations.home-lab.config.system.build.toplevel' 2>&1 | tail -3
```

Expected: all green / build.

- [ ] **Step 2: Spot-check generated tree**

```bash
out=$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.homeConfigurations."mr-fw16@fw16".activationPackage')
find "$out/home-files" -type f | sort
```

Confirm against spec §3: git config, zed/\*.json, lazygit, mise, fastfetch, gallery-dl, topgrade, tombi, herdr, soar, opencode, copier, nix.conf, shellcheckrc, cargo config, bin scripts, zsh functions.

- [ ] **Step 3: grep for things that must be absent**

```bash
git grep -nE 'mcfly|antidot init|programs\.mcfly' -- 'nix/**' || echo "clean"
```

Expected: `clean` (no mcfly / antidot runtime in nix modules).

- [ ] **Step 4: Update the AI work log**

Append a closing entry to `.agents/logs/2026-08-29.md` per AGENTS.md (Actions covering Tasks 1–9, Outcome ✅).

- [ ] **Step 5: Commit the log**

```bash
git add .agents/logs/2026-08-29.md docs/superpowers/specs/2026-08-29-chezmoi-to-nix-migration-design.md
git commit -m "$(cat <<'EOF'
docs: log chezmoi → Home Manager migration completion

Co-authored-by: Claude Sonnet 5 via Claude Code <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RzMeF8z1VoKPqDjuTZPHY6
EOF
)"
```

- [ ] **Step 6: Hand off**

Report the branch state and remaining out-of-scope phases (spec §1.3 / §9): NixOS `fw16` host, KDE/Plasma via plasma-manager, Flatpak pass. Offer `superpowers:finishing-a-development-branch`.

---

## Self-review notes

**Spec coverage:**

- §1.1 decisions: flake inputs (T1), username split (T2), fw16 stub (T3), shell (T4), git+option (T5), zed (T6), dev-tools+mise (T7), packages+gui gate (T8), verbatim/soar/antidot-config/opencode (T9). mcfly drop (T4), KDE/Plasma + Flatpak explicitly out (T10 handoff).
- §3.1–§3.8 module shapes: T3, T5, T6, T7, T8, T9, T4 respectively.
- §4 flake changes: T1.
- §5 exclusions: enforced by Global Constraints + not creating those files.
- §6 implementation order: matches T1→T10.
- §7 verification: T10.

**Placeholder scan:** The `userSettings` / `globalConfig.tools` / `settings` bodies in T6/T7 say "transcribe from <file>" rather than inlining ~200 lines of JSON — this is deliberate (the source files are the authority and are read in Step 1 of each task), and each is bounded to one named file with explicit transform rules (strip comments, drop these keys). Acceptable per "repeat the code" spirit since the code IS a file the executor opens, not another task.

**Type consistency:** `mine.git.{userName,userEmail,signingKey}` (str, default "") used identically in T5 option def and T3/T5 stub. `mine.gui.enable` (bool, default false) consistent T8 def ↔ T3/T8 stub. `flake.modules.home.{common,mr-nix}` import path consistent T2/T3.

**Known soft spots the executor must resolve live:**

- Exact nixpkgs attr paths for ~40 packages (T8 Step 2 — resolve via mcp-nixos).
- Whether `programs.git.delta.options` accepts every key or some must move to `extraConfig` (T5 Step 3 note).
- `llm-agents.overlays.shared-nixpkgs` attr name (T1 Step 4 fallback).
- Where standalone HM writes session vars on genericLinux (T4 Step 8).
