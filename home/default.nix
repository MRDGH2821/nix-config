{
  nix-openclaw,
  sops-nix,
  lib,
  ...
}: let
  autoImportLib = import ../../mylib/auto-import.nix {inherit lib;};
in {
  imports =
    autoImportLib.autoImportModules ./.
    ++ autoImportLib.autoImportFolders ./.
    ++ [
      nix-openclaw.homeManagerModules.openclaw
      sops-nix.homeManagerModules.sops
    ];

  programs.home-manager.enable = true;
}
