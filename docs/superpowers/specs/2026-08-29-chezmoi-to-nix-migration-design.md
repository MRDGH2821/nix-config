# Chezmoi → Nix Home Manager Migration Design Specification

- **Date**: 2026-08-29
- **Branch**: `feat/migrate-chezmoi`
- **Depends on**: [Blueprint Home Manager Phase 2](./2026-08-05-blueprint-home-manager-phase-2-design.md)
- **Source repo**: `~/.local/share/chezmoi/` (chezmoi root = `files/`)
- **Docs**: [Blueprint folder structure — users](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)

## 1. Overview

The chezmoi repo `files/` tree is a cross-platform (Fedora / Arch / Debian / Ubuntu / Windows, KDE) daily-driver dotfile set. This workstream ports the **portable, non-Windows, non-distro-installer** parts into Blueprint Home Manager modules under `nix/modules/home/`, consumed by the interactive account on the **Framework 16** laptop.

Phase 2 wired Home Manager for `mr-nix` on `home-lab` / `test-bed` (wire-up only). This phase (call it Phase 3) adds the actual user environment: shell finishing, `programs.*` for dev tools and editor, `home.packages`, and a verbatim long-tail — plus a new `fw16` host.

### 1.1 Decisions

| Topic                     | Choice                                                                                                                                                                                                                  |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| End state                 | **Staged**: build a Home Manager layer that works **standalone on Fedora now**, structured so a future NixOS `fw16` host adopts the same shared modules                                                                 |
| Host                      | New `nix/hosts/fw16/` — `users/` stub now; `configuration.nix` + `hardware-configuration.nix` deferred to the NixOS phase                                                                                               |
| Standalone account        | **Split**: `hosts/fw16/users/mr-fw16.nix` (matches the real Fedora login `mr-fw16` / `/home/mr-fw16`). All real config lives in shared `homeModules` that both `mr-fw16` (standalone) and `mr-nix` (NixOS hosts) import |
| Migration style           | **Nativize where possible** — `programs.*` regenerating config from Nix; `xdg.configFile` / `home.file` only for apps with no module or not worth modelling                                                             |
| Packages                  | **Everything portable** — every chezmoi-listed package that exists in nixpkgs (or `llm-agents.nix`), GUI apps included                                                                                                  |
| `mise`                    | **Keep** — `programs.mise` with `globalConfig` port; complements Nix for non-Nix project toolchains                                                                                                                     |
| `mcfly`                   | **Drop** — fzf history widget + `zsh-history-substring-search` already configured in `shell/zsh.nix`                                                                                                                    |
| `soar` + `antidot`        | **Keep configs** (verbatim `xdg.configFile`); binaries are out-of-band (not in nixpkgs, not packaged here)                                                                                                              |
| Signing key / GPG         | **Module option** — expose via a home-module option (`vars`-style), set per host/stub, not hardcoded in `git.nix`                                                                                                       |
| opencode config           | **Migrate verbatim** — `xdg.configFile` for `opencode.json` + `tui.json`                                                                                                                                                |
| KDE / Plasma              | **Future plan** — `dolphinrc`, `konsolerc`, `spectaclerc`, konsole profiles, `plasma-workspace/env/*`, `kxmlgui5` are out of scope here (separate `plasma-manager` workstream)                                          |
| Flatpak / non-nixpkgs GUI | **Future plan** — Grayjay, Alpaca, planify, onlyoffice, ente-auth, Flatseal, Warehouse, Snapshot, Gramps, Firmware, etc. handled in a later `services.flatpak` pass                                                     |
| `nixos-hardware`          | Add `github:NixOS/nixos-hardware` flake input now; the `framework-16` AMD profile is imported later by `hosts/fw16/configuration.nix`                                                                                   |
| `llm-agents.nix`          | Add `github:numtide/llm-agents.nix` flake input; consume via `overlays.shared-nixpkgs` → `pkgs.llm-agents.*` for `herdr`, `rtk`, `apm`, `hermes-agent`                                                                  |

### 1.2 Success criteria

- New flake inputs `nixos-hardware` and `llm-agents` present; `llm-agents` overlay applied.
- `nix/hosts/fw16/users/mr-fw16.nix` exists and builds as `.#mr-fw16@fw16`.
- Shared `homeModules` cover: git, zed, dev-tools (lazygit/mise/direnv/gh/topgrade/gallery-dl/tombi/fastfetch), packages, misc verbatim configs, extended shell (aliases/functions/session-vars).
- `home.username` is **not** hardcoded in shared modules — it comes from the host stub / Blueprint path.
- `just check` (`nix flake check`) passes.
- `nix build .#mr-fw16@fw16.activationPackage` succeeds on `x86_64-linux`.
- Existing `home-lab` / `test-bed` `mr-nix` configs still evaluate (they may opt into new shared modules but must not break).
- No Windows, `.chezmoiscripts`, distro package YAML, chezmoi templating, `antidot` runtime hooks, or `bose-game` content added.

### 1.3 Non-goals (later phases)

- NixOS `fw16` host: bootloader, disko/partitions, `hardware-configuration.nix`, `nixos-hardware` import, desktop/session, system users.
- KDE/Plasma personal config (`plasma-manager`).
- Flatpak + non-nixpkgs GUI apps.
- Packaging `soar` / `antidot` for Nix.
- Migrating `home-lab` / `test-bed` to the new shared modules (they _may_ adopt them, decided during implement; not required).
- Espanso config, `marktext` config, `gallery-dl` beyond `config.json`.

---

## 2. Target layout

```text
nix/
  modules/home/
    common.nix                 # UPDATE — import ./shell already; keep stateVersion
    shell/
      default.nix              # UPDATE — add ./session-vars.nix (+ ./functions.nix)
      aliases.nix              # UPDATE — port shell_aliases.sh aliases
      functions.nix            # NEW — line, rmedirs, touchfile, export-gh, export-glab, update-repo
      session-vars.nix         # NEW — EDITOR/VISUAL/PAGER, SELINUX_MODE, PATH extras (soar/bin, .local/bin)
      zsh.nix                  # UPDATE — fold in .zshrc.d completions (uv, cargo); drop mcfly
    mr-nix/                     # shared "interactive account" modules (name kept for continuity)
      default.nix              # UPDATE — import new siblings; do NOT set home.username
      keepassxc.nix            # (exists)
      git.nix                 # NEW — programs.git full port + options.mine.git.{signingKey,gpgRecipient}
      zed.nix                 # NEW — programs.zed-editor (userSettings/userKeymaps/userTasks/extensions)
      dev-tools.nix           # NEW — lazygit, mise, direnv, gh, topgrade, gallery-dl, tombi, fastfetch
      packages.nix            # NEW — home.packages (portable set, incl. pkgs.llm-agents.*)
      misc-configs.nix        # NEW — xdg.configFile / home.file verbatim long-tail
  hosts/
    fw16/
      users/
        mr-fw16.nix           # NEW — standalone stub: imports shared homeModules, sets username/homeDir, git option values
    home-lab/users/mr-nix.nix  # unchanged (optionally adopt shared modules — implement-time call)
    test-bed/users/mr-nix.nix  # unchanged
```

`home.username` moves **out** of `modules/home/mr-nix/default.nix` (per Decision 1.1 "Split") and into each consumer stub, so the same modules serve `mr-fw16` and `mr-nix`.

---

## 3. Module shapes

### 3.1 `hosts/fw16/users/mr-fw16.nix`

```nix
{ flake, ... }: {
  imports = [
    flake.modules.home.common
    flake.modules.home.mr-nix
  ];

  home.username = "mr-fw16";
  home.homeDirectory = "/home/mr-fw16";

  mine.git = {
    signingKey   = "<gpg-signing-key-id>";   # from chezmoi dot_config/git/config [user].signingkey
    gpgRecipient = "<gpg-recipient-fingerprint>";   # from chezmoi .chezmoi.toml.tmpl [gpg].recipient
    userName = "MRDGH2821";
    userEmail = "ask.mrdgh2821@outlook.com";
  };
}
```

Standalone activation:

```bash
nix run home-manager -- switch --flake .#mr-fw16@fw16
```

### 3.2 `modules/home/mr-nix/default.nix` (updated)

```nix
{...}: {
  imports = [
    ./keepassxc.nix
    ./git.nix
    ./zed.nix
    ./dev-tools.nix
    ./packages.nix
    ./misc-configs.nix
  ];
  # home.username intentionally NOT set here — consumer stub owns identity.
}
```

The NixOS host stubs (`hosts/home-lab/users/mr-nix.nix`, `hosts/test-bed/users/mr-nix.nix`) gain `home.username = "mr-nix";` (Blueprint may already derive it from the path — confirm during implement; keep only if needed).

### 3.3 `modules/home/mr-nix/git.nix`

Exposes an options block and consumes it:

```nix
{ lib, config, ... }:
let cfg = config.mine.git;
in {
  options.mine.git = {
    userName     = lib.mkOption { type = lib.types.str; };
    userEmail    = lib.mkOption { type = lib.types.str; };
    signingKey   = lib.mkOption { type = lib.types.str; description = "GPG signing key id/fpr for git commit.gpgsign."; };
    gpgRecipient = lib.mkOption { type = lib.types.str; description = "GPG recipient fingerprint (chezmoi/parity; informational unless used)."; };
  };

  config.programs.git = {
    enable = true;
    userName = cfg.userName;
    userEmail = cfg.userEmail;
    signing = { key = cfg.signingKey; signByDefault = true; };
    delta = {
      enable = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Dracula";
        navigate = true;
      };
    };
    extraConfig = {
      init.defaultBranch = "main";
      init.templateDir = "~/.config/git/templates";
      merge = { ff = "only"; guitool = "meld"; };
      push.followTags = true;
      log.showSignature = true;
      tag = { forceSignAnnotated = true; gpgsign = true; };
      interactive.diffFilter = "delta --color-only";
      credential = {
        helper = [ "cache --timeout 21600" "libsecret" "oauth" ];
        "https://github.com".helper = "!gh auth git-credential";
        "https://gist.github.com".helper = "!gh auth git-credential";
        "https://gitlab.com".helper = "!glab auth git-credential";
      };
      # includeIf blocks preserved verbatim (config-axisnexa / config-unimelb
      # referenced files are NOT managed here — user drops them or they no-op).
      # Rendered via extraConfig attr keys: `includeIf "gitdir/i:**/AxisNexa/"`.
    };
  };
}
```

Notes:

- chezmoi's `core.editor = "zed -n --wait"` / `core.pager = "/usr/bin/delta ..."` → HM sets `core.editor` from `programs.git` + delta integration; absolute `/usr/bin/*` paths dropped (Nix `PATH`).
- The `git/templates/hooks/{commit-msg,pre-commit}` executables → `home.file."./.config/git/templates/hooks/..." = { source = ...; executable = true; }` in `misc-configs.nix`, OR `programs.git.hooks` if the content is generic. Preserve as files (they are chezmoi-tracked scripts).
- `includeIf` referenced configs (`config-axisnexa`, `config-unimelb`) are **not** in the chezmoi `files/` tree — left unmanaged.

### 3.4 `modules/home/mr-nix/zed.nix`

- `programs.zed-editor.enable = true`
- `programs.zed-editor.package` — GUI Zed only makes sense on a desktop; on standalone Fedora set `package = null` or `pkgs.zed-editor` per host. Keep `installRemoteServer` default.
- `userSettings` = the JSON from `dot_config/zed/private_settings.json`, minus machine-specific noise (telemetry keys stay as-is; `terminal_init_command = "herdr-open"` kept).
- `userKeymaps` = `dot_config/zed/keymap.json` array.
- `userTasks` = `dot_config/zed/tasks.json` array.
- `extensions` = keys of `auto_install_extensions` that are `true`.
- `mutableUserSettings`/`mutableUserKeymaps`/`mutableUserTasks` — set `false` for full declarative control (default), or `true` if the user wants Zed to keep writing them. **Default `false`; revisit if it fights the GUI.**
- `context_servers.mcp-nixos` already in the JSON — keep.

### 3.5 `modules/home/mr-nix/dev-tools.nix`

| Program               | Source                              | Target                                                                                                                                           |
| --------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `programs.lazygit`    | `dot_config/lazygit/config.yml`     | `.settings` = YAML as attrs. `os.editPreset = "zed"`, delta diffRenderer kept (drop `/usr/bin/` prefix)                                          |
| `programs.mise`       | `dot_config/mise/config.toml`       | `.globalConfig.tools` = the tool map. `enableMutableConfig = true` (user runs `mise use`). `enableZshIntegration = true`                         |
| `programs.direnv`     | `.zshrc.d/12-direnv`                | `.enable = true`, `.nix-direnv.enable = true` (repo already uses direnv)                                                                         |
| `programs.gh`         | git credential helper refs          | `.enable = true`, `.settings.git_protocol = "https"`                                                                                             |
| `programs.topgrade`   | `dot_config/topgrade.toml`          | `.settings` = TOML as attrs                                                                                                                      |
| `programs.gallery-dl` | `dot_config/gallery-dl/config.json` | `.settings` = JSON as attrs                                                                                                                      |
| `programs.fastfetch`  | `dot_config/fastfetch/config.jsonc` | `.settings` = the JSONC object (strip comments). Fix hardcoded paths (`/home/arch/...weather.sh`, ISOz disk) — drop those modules or parametrise |
| `tombi`               | `dot_config/tombi/config.toml`      | no HM module → `xdg.configFile."tombi/config.toml"` in misc-configs                                                                              |

### 3.6 `modules/home/mr-nix/packages.nix`

`home.packages` from chezmoi package sources, nixpkgs names (verified present unless noted):

**CLI / dev:** `bat fd ripgrep fzf zoxide direnv gh glab lazygit git-cliff cocogitto copier cspell fastfetch nodejs bun uv yq jq prek typos shfmt shellcheck ls-lint keep-sorted rumdl tombi typstyle typst repgrep topgrade oh-my-posh btop tmux sccache rustup git-delta git-credential-oauth tealdeer nvtopPackages.full syncthing`
**From `pkgs.llm-agents`:** `herdr rtk apm hermes-agent`
**GUI (portable; desktop host will actually use them):** `firefox keepassxc kleopatra vlc meld discord obs-studio heroic marktext sourcegit` — GUI set gated behind a `mine.gui.enable` option (off for standalone-on-Fedora unless wanted, on for the future desktop host).
**Rust extras (`rust.yaml`):** `cargo-edit cargo-update cargo-cache ludusavi cargo-binstall` (nixpkgs) + `prettypst` (nixpkgs). `git-agecrypt` already a flake concern (`git-agecrypt.toml` in repo).

**Not packaged (documented, left to out-of-band):** `soar`, `antidot`, `uv-upx`, `betterleaks`, `hk`, `mcfly` (dropped), `espanso-wayland` (later), `steam` (NixOS `programs.steam`, later desktop phase), flatpak apps (later).

**Skipped (Nix-native / provided elsewhere):** `nix` (system), `podman` (NixOS `virtualisation.podman`), `alejandra` + `treefmt` (flake devshell), `chezmoi` (being retired).

`nodePackages.sort-package-json` / `npm:sort-package-json@4` → `sort-package-json` if in nixpkgs, else skip.

### 3.7 `modules/home/mr-nix/misc-configs.nix`

Verbatim drops (`xdg.configFile` unless noted). Each `source` points at a copy vendored into `nix/modules/home/mr-nix/files/` (extract chezmoi templating first — render once, commit the plain file):

| Target path                                                                     | From                                            | Notes                                                                                               |
| ------------------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `herdr/config.toml`                                                             | `dot_config/herdr/config.toml`                  | static                                                                                              |
| `soar/config.toml`, `soar/packages.toml`                                        | `dot_config/soar/*`                             | binary out-of-band                                                                                  |
| `opencode/opencode.json`, `opencode/tui.json`                                   | `dot_config/opencode/*`                         | verbatim per decision                                                                               |
| `topgrade` handled by module                                                    | —                                               | —                                                                                                   |
| `tombi/config.toml`                                                             | `dot_config/tombi/config.toml`                  | no module                                                                                           |
| `~/.config/cargo/config.toml` (`home.file`)                                     | `dot_local/share/cargo/config.toml`             | sccache wrapper; ensure `CARGO_HOME` set in session-vars                                            |
| `nix/nix.conf`                                                                  | `dot_config/nix/nix.conf`                       | OR fold into NixOS `nix.settings` on the future host; keep as user `nix.conf` for standalone Fedora |
| `copier/settings.yml`                                                           | `dot_config/copier/settings.yml`                | trust list                                                                                          |
| `~/.shellcheckrc` (`home.file`)                                                 | `dot_shellcheckrc`                              | —                                                                                                   |
| `~/.local/bin/cspell-refresh-words` (`home.file`, executable)                   | `dot_local/bin/executable_cspell-refresh-words` | needs `yq`, `bunx` on PATH                                                                          |
| `~/.local/bin/herdr-open` (`home.file`, executable)                             | `dot_local/bin/executable_herdr-open`           | needs `herdr`, `yq`, `git`                                                                          |
| `git/templates/hooks/commit-msg`, `git/templates/hooks/pre-commit` (executable) | `dot_config/git/templates/hooks/executable_*`   | referenced by `init.templateDir`                                                                    |
| `fastfetch` handled by module                                                   | —                                               | —                                                                                                   |
| `MangoHud/MangoHud.conf`                                                        | `dot_config/MangoHud/MangoHud.conf`             | **defer** to desktop phase (`programs.mangohud`)                                                    |

### 3.8 `modules/home/shell/` updates

**`session-vars.nix`** (`home.sessionVariables` + `home.sessionPath`):

```nix
{
  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    PAGER = "less";
    CARGO_HOME = "$HOME/.local/share/cargo";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/soar/bin"
    "$HOME/.local/share/cargo/bin"
  ];
}
```

- Drop `SELINUX_MODE`/`getenforce` (NixOS has no SELinux; on Fedora it is harmless but noisy — omit).
- XDG base dirs: HM sets these; do not re-export.
- `antidot init` / `soar` PATH: PATH entry kept; `antidot init` eval **dropped** (declarative env).
- AppImages / bun cache / opencode / mise shims PATH: `mise` shims via `programs.mise` zsh integration; `~/.opencode/bin` + bun cache kept only if the user still bootstraps those outside Nix — **add opt-in note, default omit**.

**`functions.nix`** — port shell functions from `.chezmoitemplates/shell-scripts/shell_aliases.sh` into `programs.zsh.initContent` (and bash if `programs.bash.enable`): `line`, `rmedirs`, `touchfile` (already partly in `zsh.nix` — dedupe), `export-gh`, `export-glab`, `update-repo`.

**`aliases.nix`** — merge in: `dnf`→`dnf5` (drop, non-NixOS-ish; keep for Fedora phase only), `tb`, `tf`, `cat`→`bat --paging=never` (already present), `ll`/`la`/`l` (eza integration already provides — verify), `bunx`→`bun x`, conditional `zed`→`zeditor`.

**`zsh.nix`** — remove any mcfly reference (none currently); add `uv`/`uvx` + `rustup`/`cargo` completion setup from `.zshrc.d/11-uv.sh` + `13-cargo.sh` into `initContent` (guarded by `command -v`). oh-my-posh random-theme logic already present — verify parity with `00-oh-my-posh.sh` (chezmoi uses `~/.cache/oh-my-posh/themes`; Nix uses `${pkgs.oh-my-posh}/share/...` — Nix version is correct, keep).

---

## 4. Flake changes

`nix/../flake.nix` inputs — add:

```nix
nixos-hardware.url = "github:NixOS/nixos-hardware";
llm-agents.url = "github:numtide/llm-agents.nix";
# llm-agents pins its own nixpkgs; do NOT `follows` (it ships a binary cache).
```

Apply the `llm-agents` overlay so `pkgs.llm-agents.*` resolves in home modules. With Blueprint, add to `outputs`:

```nix
inputs.blueprint {
  inherit inputs;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  prefix = "nix";
};
```

(Confirm Blueprint accepts `nixpkgs.overlays` here; if not, apply the overlay inside a shared module via `nixpkgs.overlays` in the HM/NixOS module or `_module.args`.)

Add substituter for the `llm-agents` cache to `nix.settings` on the future host / to `nixConfig` if the standalone build should use it.

---

## 5. Explicitly excluded from `files/`

| Path / group                                                                                                                                       | Reason                                                                                   |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `readonly_Documents/**`, `dot_config/powershell/**`, `.chezmoiscripts/windows/**`                                                                  | Windows                                                                                  |
| `.chezmoiscripts/**` (all)                                                                                                                         | distro configure + package-install scripts; replaced by Nix                              |
| `.chezmoidata/packages/linux/{arch,debian,ubuntu,fedora}.yaml`, `.chezmoidata/distros.yaml`                                                        | package manifests → `home.packages` / future NixOS                                       |
| `.chezmoidata/skills.yaml` (empty), `.chezmoidata/packages/python3.yaml` (`uv-upx`)                                                                | empty / out-of-band                                                                      |
| `dot_config/paru/**`                                                                                                                               | Arch AUR helper                                                                          |
| `.chezmoi.toml.tmpl`, `.chezmoitemplates/**`, `.chezmoiignore`, `dot_config/copier` templating                                                     | chezmoi machinery (render once, keep output only)                                        |
| `dot_local/share/antidot/{alias,env}.sh`, `antidot init` hooks                                                                                     | `$HOME` XDG-cleanup; moot on Nix. `antidot` config kept only if it exists (none in tree) |
| `dot_bashrc` "content outside managed sections" self-check                                                                                         | HM owns `~/.bashrc`                                                                      |
| `dot_config/{dolphinrc,konsolerc,spectaclerc.tmpl}`, `dot_config/plasma-workspace/**`, `dot_local/share/konsole/**`, `dot_local/share/kxmlgui5/**` | KDE/Plasma — future `plasma-manager` phase                                               |
| `dot_config/MangoHud/**`                                                                                                                           | future desktop phase (`programs.mangohud`)                                               |
| `dot_config/marktext/**`                                                                                                                           | app-managed state                                                                        |
| `.chezmoitemplates/shell-scripts/{01-chezmoi,02-mcfly,03-antidot}.sh`                                                                              | chezmoi retired / mcfly dropped / antidot dropped                                        |
| `dot_config/{dolphinrc → private_*}` and `readonly_*`                                                                                              | KDE / Windows                                                                            |

---

## 6. Implementation order

1. **Flake inputs** — add `nixos-hardware`, `llm-agents`; wire `llm-agents` overlay; `just check`.
2. **De-hardcode username** — move `home.username` out of `modules/home/mr-nix/default.nix` into `home-lab` / `test-bed` stubs; `just check` (both hosts still evaluate).
3. **`fw16` host + stub** — `nix/hosts/fw16/users/mr-fw16.nix`; confirm `.#mr-fw16@fw16` appears in `nix flake show`.
4. **shell/** — `session-vars.nix`, `functions.nix`, `aliases.nix` merge, `zsh.nix` completions; `default.nix` imports.
5. **git.nix** — options block + `programs.git`; set values in `mr-fw16.nix` stub.
6. **zed.nix** — settings/keymap/tasks/extensions; vendor JSON.
7. **dev-tools.nix** — lazygit, mise, direnv, gh, topgrade, gallery-dl, fastfetch.
8. **packages.nix** — portable set + `mine.gui.enable` option; `pkgs.llm-agents.*`.
9. **misc-configs.nix** — vendor rendered files into `modules/home/mr-nix/files/`; `xdg.configFile` / `home.file`.
10. `nix build .#mr-fw16@fw16.activationPackage`; `just check`.
11. Commit(s) — Conventional Commits + AI `Co-authored-by` trailer; scope `services` or a new `home` scope (add to `cog.toml` if missing).
12. Implementation plan step (writing-plans) splits 4–9 into per-module tasks.

---

## 7. Verification

| Check                                                      | Expectation                                                             |
| ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| `just check` / `nix flake check`                           | Pass                                                                    |
| `nix flake show`                                           | Lists `mr-fw16@fw16`                                                    |
| `nix build .#mr-fw16@fw16.activationPackage`               | Builds on `x86_64-linux`                                                |
| `nix eval .#homeModules --apply 'x: builtins.attrNames x'` | includes `common`, `mr-nix`                                             |
| `home-lab` / `test-bed` eval                               | still build                                                             |
| generated `~/.config/git/config`                           | matches chezmoi semantics (signing, delta, includeIf, credential stack) |
| generated `~/.config/zed/settings.json`                    | parity with `private_settings.json` (minus mutable-state churn)         |
| grep `nix/` for `mcfly`, `antidot init`, `chezmoi`         | absent (docs/logs exempt)                                               |

Manual (standalone Fedora):

```bash
nix run home-manager -- switch --flake .#mr-fw16@fw16 -b hm-bak
exec zsh   # prompt, aliases, functions, completions, mise, direnv
git config --show-origin --get commit.gpgsign
```

---

## 8. Risks and mitigations

| Risk                                                                                 | Mitigation                                                                                                                                    |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Blueprint rejects `nixpkgs.overlays` arg                                             | apply `llm-agents` overlay inside a shared module (`nixpkgs.overlays = [...]`) instead                                                        |
| `llm-agents` inputs bloat `flake.lock` / eval time                                   | don't `follows` its nixpkgs; rely on its cache; pin and update deliberately                                                                   |
| Standalone HM on Fedora: `nix.conf` / `programs.*` assume NixOS paths                | test `activationPackage` build; keep `targets.genericLinux = true` if HM needs it for non-NixOS                                               |
| Zed `mutableUserSettings=false` fights the GUI (Zed rewrites settings)               | start `false`; flip to `true` + `home.activation` seed if friction                                                                            |
| `fastfetch` config has hardcoded foreign paths (`/home/arch`, ISOz, weather.sh)      | strip/replace those modules during port; document removed modules                                                                             |
| `home.username` still auto-set by Blueprint from path → conflict with stub `mkForce` | prefer path-derived; only set explicitly where Blueprint doesn't; use `lib.mkForce` only if eval demands                                      |
| chezmoi templating hides host-specific values (gpu, devicetype, pcloudfolder)        | those drive KDE/rclone/desktop — all out of scope here; when rendering verbatim files, render for `linux`/`fedora`/`laptop` and commit output |
| `git/templates/hooks` scripts assume tools on PATH                                   | ensure `packages.nix` provides them (`prek`, etc.); or point `init.templateDir` at an HM-built dir                                            |
| Package name drift in nixpkgs (`nvtop`→`nvtopPackages.full`, `tealdeer`/`tlrr`)      | resolve each via `mcp-nixos` at implement time; keep a "not found" list in the plan                                                           |
| Duplicate `touchfile` (in `zsh.nix` and `functions.nix`)                             | single definition in `functions.nix`; remove from `zsh.nix`                                                                                   |

---

## 9. Relationship to prior phases

- Phase 1: Blueprint-native NixOS, `flake.lib` barrels, vars under `modules/nixos`.
- Phase 2: Home Manager discovery for `mr-nix` on `home-lab` / `test-bed` (wire-up only).
- **Phase 3 (this doc): chezmoi `files/` → shared `homeModules` + new `fw16` standalone account.**
- Phase 4 (later): NixOS `fw16` host (bootloader, disko, `nixos-hardware`, desktop, system users).
- Phase 5 (later): KDE/Plasma via `plasma-manager`.
- Phase 6 (later): Flatpak + non-nixpkgs GUI apps.

---

## 10. Spec self-review notes

- **Placeholders:** `hardware-configuration.nix`, KDE, flatpak, `fw16` NixOS host are explicit non-goals with named later phases — not TBDs in this scope.
- **Consistency:** username is de-hardcoded in §2/§3.2 and the stub sets it in §3.1; `mcfly` dropped in §1.1/§3.8/§7; `soar`/`antidot` config-only in §1.1/§3.6/§3.7/§5.
- **Scope:** one implementation plan, ~7 new small modules + 1 stub + flake input edit. Sized like Phase 2 but larger; splittable per §6.11.
- **Ambiguity resolved:** "everything portable" = nixpkgs-or-`llm-agents` only; anything absent is listed as out-of-band, not silently dropped. GUI packages gated behind `mine.gui.enable` so the standalone Fedora build stays lean.

---

## Implemented

Phase 3 is done. Executed via [the implementation plan](../plans/2026-08-29-chezmoi-home-manager-migration.md) (Tasks 1–10) on branch `mihir/feat/chezmoi-home-manager`. All flake checks and the `mr-fw16@fw16` / `mr-nix@home-lab` / NixOS `home-lab` / `test-bed` builds pass. Phases 4–6 (NixOS `fw16` host, KDE/Plasma, Flatpak) remain out of scope.
