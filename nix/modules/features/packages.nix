{ pkgs, lib, ... }:
{
  environment.systemPackages =
    with pkgs;
    map lib.lowPrio [
      curl
      gitMinimal
      neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      git
      wget
      curl
    ];
}
