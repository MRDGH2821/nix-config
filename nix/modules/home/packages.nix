# Ported from the chezmoi `.chezmoidata/packages/**` YAML, `dot_config/mise/config.toml`
# `[tools]`, and `.chezmoidata/packages/rust.yaml`.
#
# cspell:ignore syncthingplasmoid kdialog -- verbatim Fedora package / helper-binary
# names referenced in the comments below.
#
# Deliberately NOT added here (owned elsewhere / out of scope):
#   - bat, direnv, eza, fastfetch, fzf, gh, lazygit, oh-my-posh, topgrade, zoxide
#     -> installed by their dedicated `programs.*` modules (shell/, dev-tools.nix).
#   - git-delta -> pulled in by `programs.delta` (git.nix).
#   - keepassxc -> installed by `programs.keepassxc` (keepassxc.nix).
#   - alejandra, treefmt -> provided by the flake devshell / `nix fmt`.
#   - nix, podman, pam-u2f, sane-backends, system-config-printer -> system level.
#   - chezmoi (retired), mise (programs.mise), soar / antidot (misc-configs.nix),
#     mcfly (dropped), espanso, steam, flatpak apps, tailscale, calibre, ollama
#     -> later phases / rules.
#
# not available in nixpkgs (or unbuildable) — tracked, not blocking:
#   - apm            : llm-agents overlay ships it, but the build fails against our
#                      nixpkgs pin (pythonRuntimeDepsCheck: `websockets not installed`).
#                      Covered at runtime by mise (`apm = "latest"`).
#   - git-credential-libsecret : no standalone attr — only bundled in `pkgs.gitFull`.
#                      The Fedora system git provides the helper; git.nix's
#                      `credential.helper = ["libsecret"]` resolves it from PATH.
#   - sort-package-json : npm-only, not packaged for nixpkgs. Managed via mise
#                      (`npm:sort-package-json`).
#   - syncthingplasmoid-qt6 / syncthingtray-qt6 : Fedora/KDE tray integration;
#                      later desktop-integration phase.
#   - mangohud       : in nixpkgs (+ `programs.mangohud`); deferred to the gaming phase.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # CLI / dev
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

    # from the llm-agents overlay — `apm` omitted, see header
    llm-agents.herdr
    llm-agents.hermes-agent
    llm-agents.rtk

    # GUI
    discord
    firefox
    heroic
    kdePackages.kleopatra
    ludusavi # game-save backup
    marktext
    meld
    obs-studio
    sourcegit
    vlc
  ];
}
