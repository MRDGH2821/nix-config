{
  nix-openclaw,
  sops-nix,
  ...
}: {
  imports = [
    ../modules
    nix-openclaw.homeManagerModules.openclaw
    sops-nix.homeManagerModules.sops
  ];
  home = {
    username = "bose-game";
    homeDirectory = "/home/bose-game";
    stateVersion = "25.05";
  };
  programs.home-manager.enable = true;
}
