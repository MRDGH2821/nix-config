# Full Home Manager stack for inspecting dotfile layout in the test-bed VM.
{
  flake,
  lib,
  ...
}: {
  home = {
    homeDirectory = "/home/mr-fw16";
    stateVersion = lib.mkForce "26.11";
    username = "mr-fw16";
  };
  home.file."Desktop/home-manager-layout.txt".text = ''
    Home Manager preview — where things live
    ========================================

    Shell & CLI
      ~/.zshrc, ~/.config/zsh/     — zsh + Oh My Zsh
      ~/.config/bat, eza, fzf, zoxide

    Dev tools
      ~/.config/lazygit, mise, topgrade, fastfetch, gallery-dl
      ~/.local/share/cargo/config.toml

    Editor
      ~/.config/zed/               — Zed settings, keymaps, tasks

    Git
      ~/.config/git/               — git config + hook templates

    Apps & misc
      ~/.config/{herdr,soar,opencode,tombi,copier}/
      ~/.local/bin/                — helper scripts

    Open Dolphin and browse ~/.config and ~/.local to compare with this list.
    Terminal: tree -L 2 ~/.config
  '';
  imports = with flake.homeModules; [
    common
    dev-tools
    git
    keepassxc
    misc-configs
    packages
    zed
  ];
}
