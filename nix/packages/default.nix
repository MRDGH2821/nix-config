{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    map lib.lowPrio [
      curl
      curl
      git
      gitMinimal
      nano
      neovim
      wget
    ];
}
