# Native Syntax Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize NixOS, Home Manager, and host modules across the codebase to modern, native, concise, and non-verbose syntax compatible with Numtide Blueprint.

**Architecture:** Refactor legacy and verbose Nix module syntax across `nix/modules/nixos`, `nix/modules/home`, `nix/vars`, and `nix/hosts` to align with Numtide Blueprint patterns. Enforce concise dot-notation shorthands, eliminate redundant `let ... in` bindings and nested blocks, upgrade deprecated NixOS options (e.g., migrate `services.searx` to `services.searxng`), streamline shell and feature options using modern Home Manager / NixOS module options, and validate all host configurations with `just check`.

**Tech Stack:** Nix Flakes, Numtide Blueprint, NixOS 24.11+ / unstable modules, Home Manager options.

## Global Constraints

- Use shorter and simpler Nix syntax everywhere possible (prefer single-line dot notation like `programs.bat.enable = true;`, nested attribute merging, avoiding redundant bindings).
- Every change must maintain flake evaluation compatibility; no broken options or syntax.
- All code formatting must pass `nix fmt` (Alejandra).
- Repository validation must pass `just check` (`nix flake check`).
- Every commit must follow Conventional Commits format with a `Co-authored-by` trailer.

---

### Task 1: Migrate and Modernize Option Declarations in `nix/vars/`

**Files:**

- Modify: `nix/vars/default.nix:1-13`
- Modify: `nix/vars/networking.nix:1-55`
- Modify: `nix/vars/mr-nix-user.nix:1-33`
- Modify: `nix/vars/forgejo-runner.nix:1-185`

**Interfaces:**

- Consumes: `lib.mkOption`, `lib.types`, `lib.mkEnableOption`, `lib.mkPackageOption`
- Produces: Clean, concise, modern attribute sets and type definitions for global system variables (`persistent_storage`, `networking.*`, `services.forgejo-runner.*`).

- [ ] **Step 1: Inspect and verify current `nix/vars/` options**

Run: `nix eval .#nixosConfigurations.home-lab.config.networking.baseDomain`
Expected: Evaluates to configured string value.

- [ ] **Step 2: Streamline `nix/vars/networking.nix` with modern concise option declarations**

Replace legacy verbose submodule and option definitions with concise, formatted types in `nix/vars/networking.nix`:

```nix
{lib, ...}: {
  options.networking = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "your-new-domain.com";
      description = "Base domain for services";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "your-new-email@example.com";
      description = "Admin email address";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "your-provider";
      description = "DNS provider name for ACME/lego";
    };

    smtp = lib.mkOption {
      type = lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "smtp.example.com";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 587;
          };
          email = lib.mkOption {
            type = lib.types.str;
            default = "user@example.com";
          };
          security = lib.mkOption {
            type = lib.types.enum ["starttls" "tls" "none"];
            default = "starttls";
            description = "SMTP security mode";
          };
          username = lib.mkOption {
            type = lib.types.str;
            default = "user";
            description = "SMTP username";
          };
        };
      };
    };
  };
}
```

- [ ] **Step 3: Clean up `nix/vars/mr-nix-user.nix` user declaration with short syntax**

Refactor `nix/vars/mr-nix-user.nix` to use modern `nix.settings` and direct attribute assignments without redundant comments:

```nix
{pkgs, ...}: let
  sshKeys = import ../keys/ssh-keys.nix;
in {
  programs.zsh.enable = true;

  users.users.mr-nix = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [sshKeys.sharedKey];
    extraGroups = ["docker" "podman" "networkmanager" "wheel"];
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    allowed-users = ["@wheel" "mr-nix"];
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
```

- [ ] **Step 4: Verify nix evaluation after option cleanup**

Run: `nix eval .#nixosConfigurations.home-lab.config.users.users.mr-nix.name`
Expected: `"mr-nix"`

- [ ] **Step 5: Commit option syntax refactoring**

```bash
git add nix/vars/
git commit -m "refactor(vars): modernize option syntax using concise attributes in nix/vars

Co-authored-by: Gemini 3.6 Flash via Antigravity <noreply@google.com>"
```

---

### Task 2: Refactor Service Modules to Modern Native NixOS Syntax

**Files:**

- Modify: `nix/modules/nixos/services/searxng.nix:1-16`
- Modify: `nix/modules/nixos/services/bentopdf.nix:1-16`
- Modify: `nix/modules/nixos/services/authentik.nix:1-20`
- Modify: `nix/modules/nixos/services/postgresql.nix:1-15`

**Interfaces:**

- Consumes: `config.networking.baseDomain`, `config.sops.secrets`
- Produces: Updated service module definitions adhering to latest NixOS service schemas (`services.searxng` over `services.searx`) with simplified syntax.

- [ ] **Step 1: Update `nix/modules/nixos/services/searxng.nix` from deprecated `services.searx` to `services.searxng`**

Replace `services.searx` with concise `services.searxng` syntax in `nix/modules/nixos/services/searxng.nix`:

```nix
{config, ...}: {
  services.searx = {
    enable = true;
    redisCreateLocally = true;
    openFirewall = true;
    environmentFile = config.sops.secrets.searxng.path;
    settings.server = {
      port = 7100;
      secret_key = "$SEARXNG_SECRET";
      base_url = "https://searxng.${config.networking.baseDomain}";
    };
  };
}
```

- [ ] **Step 2: Clean up `bentopdf` and `authentik` service modules using short dot notation**

Ensure `bentopdf.nix` and `authentik.nix` use short attribute set structures:

In `nix/modules/nixos/services/bentopdf.nix`:

```nix
{config, ...}: {
  services.bentopdf = {
    enable = true;
    domain = "pdf.${config.networking.baseDomain}";
    nginx.enable = true;
  };

  services.nginx.virtualHosts."${config.services.bentopdf.domain}".listen = [
    {
      addr = "127.0.0.1";
      port = 8090;
    }
  ];
}
```

- [ ] **Step 3: Test evaluation of NixOS service configurations**

Run: `nix eval .#nixosConfigurations.home-lab.config.services.searx.enable`
Expected: `true`

- [ ] **Step 4: Commit service syntax refactoring**

```bash
git add nix/modules/nixos/services/
git commit -m "refactor(services): modernize NixOS service definitions with concise syntax

Co-authored-by: Gemini 3.6 Flash via Antigravity <noreply@google.com>"
```

---

### Task 3: Refactor Shell & Feature Modules to Concise Native Options Syntax

**Files:**

- Modify: `nix/modules/nixos/features/git.nix:1-11`
- Modify: `nix/modules/nixos/features/direnv.nix:1-7`
- Modify: `nix/modules/nixos/shell/bat.nix:1-6`
- Modify: `nix/modules/nixos/shell/zoxide.nix:1-6`
- Modify: `nix/modules/nixos/shell/zsh.nix:1-61`
- Modify: `nix/modules/home/mr-nix.nix:1-5`

**Interfaces:**

- Consumes: `pkgs`, `config`
- Produces: Streamlined feature & shell configuration using short single-line and dot notation (`programs.git`, `programs.direnv`, `programs.bat.enable = true;`, `programs.zoxide`).

- [ ] **Step 1: Streamline `git.nix`, `direnv.nix`, `bat.nix`, and `zoxide.nix` using concise syntax**

Refactor `nix/modules/nixos/features/git.nix`:

```nix
{
  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };
}
```

Refactor `nix/modules/nixos/features/direnv.nix`:

```nix
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

Refactor `nix/modules/nixos/shell/bat.nix`:

```nix
{
  programs.bat.enable = true;
}
```

Refactor `nix/modules/nixos/shell/zoxide.nix`:

```nix
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
```

- [ ] **Step 2: Clean up `zsh.nix` prompt and package attributes**

Simplify `nix/modules/nixos/shell/zsh.nix` by removing unnecessary boilerplate:

```nix
{pkgs, ...}: let
  promptInitScript = pkgs.writeShellScript "zsh-prompt-init" ''
    omp_themes_dir="${pkgs.oh-my-posh}/share/oh-my-posh/themes"
    omp_themes=($omp_themes_dir/*.json)
    num_files=''${#omp_themes[@]}
    random_index=$((RANDOM % num_files))
    random_omp_theme=''${omp_themes[$random_index]}
    eval "$(oh-my-posh init zsh --config $random_omp_theme)"
    SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
  '';
in {
  environment.systemPackages = with pkgs; [zimfw oh-my-posh];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    setOptions = ["HIST_IGNORE_ALL_DUPES" "CORRECT" "beep" "extendedglob" "nomatch" "notify"];
    promptInit = builtins.readFile promptInitScript;
    shellInit = ''
      bindkey -e
      zmodload -F zsh/terminfo +p:terminfo
    '';
    autosuggestions = {
      enable = true;
      extraConfig."ZSH_AUTOSUGGEST_MANUAL_REBIND" = "1";
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = ["main" "brackets"];
    };
  };
}
```

- [ ] **Step 3: Update `nix/modules/home/mr-nix.nix` for Home Manager standards using concise attributes**

Ensure `nix/modules/home/mr-nix.nix` follows exact Home Manager module conventions:

```nix
{
  home.username = "mr-nix";
  home.stateVersion = "26.05";
}
```

- [ ] **Step 4: Evaluate shell and program attributes**

Run: `nix eval .#nixosConfigurations.home-lab.config.programs.zsh.enable`
Expected: `true`

- [ ] **Step 5: Commit feature and shell module refactoring**

```bash
git add nix/modules/nixos/features/ nix/modules/nixos/shell/ nix/modules/home/
git commit -m "refactor(shell): use concise single-line and dot notation for shell features

Co-authored-by: Gemini 3.6 Flash via Antigravity <noreply@google.com>"
```

---

### Task 4: Refactor Host Configurations for Blueprint Alignment

**Files:**

- Modify: `nix/hosts/home-lab/configuration.nix:1-42`
- Modify: `nix/hosts/test-bed/configuration.nix:1-35`
- Modify: `nix/hosts/home-lab/modules/desktop.nix:1-38`

**Interfaces:**

- Consumes: `modulesPath`, `pkgs`, `mylibFor`
- Produces: Clean, modern host configurations adhering to Blueprint conventions with concise syntax.

- [ ] **Step 1: Refactor `nix/hosts/home-lab/configuration.nix` using short syntax**

Streamline user and service configuration in `nix/hosts/home-lab/configuration.nix`:

```nix
{
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.openssh.enable = true;
  services.automatic-timezoned.enable = true;

  programs.ssh.startAgent = true;

  networking.networkmanager.enable = true;
  networking.hostName = "home-lab";

  users.users.bose-game = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5wVbxASqs1YeVPFBzUoyNCABQFDOF0/JXxGrz2u215 Bose Game Mini PC"
    ];
  };

  nix.settings.allowed-users = ["@wheel" "bose-game"];

  system.stateVersion = "25.05";
}
```

- [ ] **Step 2: Refactor `nix/hosts/home-lab/modules/desktop.nix`**

Streamline `desktop.nix` to use concise `hardware.graphics` and desktop manager options:

```nix
{
  config,
  lib,
  pkgs,
  mylibFor,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
  rclone-kpxc = "/mnt/rclone/kpxc";
  mount-options = "rw";
  keepassxc-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Keepass";
    mountPoint = "${rclone-kpxc}/Keepass";
    options = mount-options;
  };
in {
  imports = [keepassxc-folder];

  services.desktopManager.plasma6.enable = true;
  services.openssh.enable = true;
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [waypipe zed-editor keepassxc];

  users.users.mr-nix.extraGroups = ["audio" "render" "video"];
}
```

- [ ] **Step 3: Test evaluation of both hosts**

Run: `nix eval .#nixosConfigurations.home-lab.config.system.build.toplevel.name`
Run: `nix eval .#nixosConfigurations.test-bed.config.system.build.toplevel.name`
Expected: Returns package derivation names for both hosts without evaluation errors.

- [ ] **Step 4: Commit host configuration refactoring**

```bash
git add nix/hosts/
git commit -m "refactor(hosts): align host configurations with concise native blueprint syntax

Co-authored-by: Gemini 3.6 Flash via Antigravity <noreply@google.com>"
```

---

### Task 5: End-to-End Validation and Code Formatting

**Files:**

- Modify: repository formatting & evaluation checks

**Interfaces:**

- Consumes: Flake checks (`formatting`, `pre-commit-check`, `nixos-home-lab`, `nixos-test-bed`, `devshell-default`, `pkgs-formatter`)
- Produces: Clean, fully verified codebase passing `just check` and `nix fmt`.

- [ ] **Step 1: Format all repository code using `nix fmt`**

Run: `nix fmt`
Expected: All Nix files formatted cleanly with Alejandra.

- [ ] **Step 2: Run `just check` to perform full flake verification**

Run: `just check`
Expected: All checks pass cleanly without errors or warnings.

- [ ] **Step 3: Commit formatting and final verification**

```bash
git add .
git commit -m "style(nix): format repository files with nix fmt

Co-authored-by: Gemini 3.6 Flash via Antigravity <noreply@google.com>"
```
