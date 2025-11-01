{lib, ...}: let
  autoImportLib = import ../../mylib/auto-import.nix {inherit lib;};
in {
  imports = lib.concatLists [
    (autoImportLib.autoImportModules ./.)
    (autoImportLib.autoImportFolders ./.)
  ];
}
