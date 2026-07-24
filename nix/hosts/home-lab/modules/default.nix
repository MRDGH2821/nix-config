{lib, ...}: let
  mylib = import ../../../lib/auto-import.nix {inherit lib;};
in {
  imports = mylib.autoImportModules ./.;
}
