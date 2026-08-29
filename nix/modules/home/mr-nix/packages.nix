# Ported from the chezmoi `.chezmoidata/packages/**` YAML, `dot_config/mise/config.toml`
# `[tools]`, and `.chezmoidata/packages/rust.yaml`.
#
# cspell:ignore syncthingplasmoid kdialog -- verbatim Fedora package / helper-binary
# names referenced in the comments below.
#
# Split:
#   - CLI / dev tools -> always installed (every host that imports `mr-nix`).
#   - GUI applications -> gated behind `mine.gui.enable` (desktop hosts only;
#     `false` on the headless NixOS `home-lab` / `test-bed`).
#
# Deliberately NOT added here (owned elsewhere / out of scope):
#   - bat, direnv, eza, fastfetch, fzf, gh, lazygit, oh-my-posh, topgrade, zoxide
#     -> installed by their dedicated `programs.*` modules (shell/, dev-tools.nix).
#   - alejandra, treefmt -> provided by the flake devshell / `nix fmt`.
#   - nix, podman, pam-u2f, sane-backends, system-config-printer -> system level.
#   - chezmoi (retired), mise (programs.mise), soar / antidot (Task 9), mcfly (dropped),
#     espanso, steam, flatpak apps, tailscale, calibre, ollama -> later phases / rules.
#
# not available in nixpkgs (or unbuildable) — tracked, not blocking:
#   - apm            : llm-agents overlay ships it, but the build fails against our
#                      nixpkgs pin (pythonRuntimeDepsCheck: `websockets not installed`).
#                      Covered at runtime by mise (`apm = "latest"`).
#   - git-credential-libsecret : no standalone attr — only bundled in `pkgs.gitFull`.
#                      On the Fedora (genericLinux) fw16 host the system git provides the
#                      helper; git.nix's `credential.helper = ["libsecret"]` resolves it
#                      from PATH.
#   - sort-package-json : npm-only, not packaged for nixpkgs. Managed via mise
#                      (`npm:sort-package-json`).
#   - syncthingplasmoid-qt6 / syncthingtray-qt6 : Fedora/KDE tray integration; the
#                      `syncthingtray` nixpkgs attr exists but belongs to a later
#                      desktop-integration phase, not this port.
#   - mangohud       : in nixpkgs (+ `programs.mangohud`); deferred to the gaming/desktop phase.
{
  config,
  lib,
  pkgs,
  ...
}: {
  config.home.packages = with pkgs;
    [
      # CLI / dev — always
      betterleaks
      btop
      bun
      cargo-binstall
      cargo-cache
      cargo-edit
      cargo-update
      cocogitto
      copier
      cspell
      fd
      git-agecrypt
      git-cliff
      git-credential-oauth
      glab
      gnupg
      hk
      jq
      keep-sorted
      ls-lint
      nodejs
      nvtopPackages.full
      prek
      prettier
      prettypst
      rclone
      repgrep
      ripgrep
      rumdl
      rustup
      sccache
      shellcheck
      shfmt
      syncthing
      tealdeer
      tmux
      tombi
      typos
      typst
      typstyle
      uv
      yq-go

      # from the llm-agents overlay (Task 1) — `apm` omitted, see header
      llm-agents.herdr
      llm-agents.hermes-agent
      llm-agents.rtk
    ]
    ++ lib.optionals config.mine.gui.enable [
      # GUI — desktop hosts only
      discord
      firefox
      heroic
      kdePackages.kleopatra
      # keepassxc: installed via programs.keepassxc (keepassxc.nix)
      ludusavi # game-save backup; GUI (pulls kdialog) — gated deliberately, not in the brief's list
      marktext
      meld
      obs-studio
      sourcegit
      vlc
    ];
  options.mine.gui.enable = lib.mkOption {
    default = false;
    description = "Install GUI applications (desktop hosts only).";
    type = lib.types.bool;
  };
}
