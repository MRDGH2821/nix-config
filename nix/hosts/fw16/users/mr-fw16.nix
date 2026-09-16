{
  flake,
  # pkgs,
  ...
}: {
  home = {
    homeDirectory = "/home/mr-fw16";
    # packages = with pkgs; [
    #   # llm-agents.claude-desktop
    # ];
    stateVersion = "26.11";
    username = "mr-fw16"; # real Fedora login on the Framework 16 (not "mr-nix")
  };
  imports = with flake.homeModules; [
    # shell # zsh + aliases + functions + session vars + bat/eza/fzf/zoxide
    # git # programs.git + delta + hooks
    # zed # programs.zed-editor + EDITOR/VISUAL
    # dev-tools # lazygit, mise, direnv, gh, topgrade, gallery-dl, fastfetch, tombi
    # packages # home.packages (CLI + GUI)
    # misc-configs # verbatim dotfile drop-ins (herdr, soar, opencode, …)
    keepassxc # KeePassXC as the org.freedesktop.secrets keyring
  ];
  # Home Manager running on Fedora, not NixOS.
  targets.genericLinux.enable = true;
}
