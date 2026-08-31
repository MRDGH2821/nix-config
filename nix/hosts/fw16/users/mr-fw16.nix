{pkgs, ...}: {
  home = {
    homeDirectory = "/home/mr-fw16";
    packages = with pkgs; [
      llm-pkgs.claude-desktop
    ];
    # Real Fedora login on the Framework 16 (not "mr-nix").
    username = "mr-fw16";
  };
  # imports = [
  #   # inputs.self.homeModules.common
  #   # inputs.self.homeModules.mr-nix
  # ];
  # mine = {
  #   git = {
  #     # Public GPG key id (not a secret); value from chezmoi dot_config/git/config -> [user].signingkey.
  #     signingKey = "1915CBA05A598D01"; # pragma: allowlist secret
  #     userEmail = "ask.mrdgh2821@outlook.com";
  #     userName = "MRDGH2821";
  #   };
  #   gui.enable = true;
  # };
  # Home Manager running on Fedora, not NixOS.
  targets.genericLinux.enable = true;
}
