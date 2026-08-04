{flake, ...}: let
  lib = flake.inputs.nixpkgs.lib;
  auto = import ../../../../lib/auto-import.nix {inherit lib;};
in {
  imports = auto.autoImportModules ./.;
}
