{
  inputs,
  pkgs,
  ...
}: {
  home = {
    homeDirectory = "/home/mr-fw16";
    packages = with pkgs; [
      llm-agents.claude-desktop
    ];
    stateVersion = "26.11";
    # Real Fedora login on the Framework 16 (not "mr-nix").
    username = "mr-fw16";
  };
  imports = [
    # KeePassXC as this user's Secret Service (org.freedesktop.secrets) keyring.
    inputs.self.homeModules.keepassxc

    # Full migrated environment (shell, git, zed, packages, dotfiles).
    # Uncomment to opt in; then also set `mine.*` below.
    # inputs.self.homeModules.common
    # inputs.self.homeModules.mr-nix
  ];
  # Needed only with homeModules.mr-nix (git identity + GUI package set):
  # mine = {
  #   git = {
  #     # Public GPG key id (not a secret); from chezmoi dot_config/git/config -> [user].signingkey.
  #     signingKey = "1915CBA05A598D01"; # pragma: allowlist secret
  #     userEmail = "ask.mrdgh2821@outlook.com";
  #     userName = "MRDGH2821";
  #   };
  #   gui.enable = true;
  # };
  # Home Manager running on Fedora, not NixOS.
  targets.genericLinux.enable = true;
}
