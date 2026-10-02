{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    curl
    git
    gitMinimal
    nano
    neovim
    wget
  ];
  programs.nix-ld.enable = true;
}
