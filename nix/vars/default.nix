{lib, ...}: let
  autoImportLib = import ../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;
  options.persistant_storage = lib.mkOption {
    type = lib.types.str;
    default = "/etc/nixos/persist/";
    description = "Path to persistant storage";
  };
}
