{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    map lib.lowPrio [
      curl
      git
      gitMinimal
      nano
      neovim
      wget
    ];
  programs.nix-ld.enable = true;
}
