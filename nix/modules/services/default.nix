{ lib, ... }:

let
  autoImportLib = import ../../mylib/auto-import.nix { inherit lib; };
in
{
  imports = autoImportLib.autoImportModules ./.;
}
