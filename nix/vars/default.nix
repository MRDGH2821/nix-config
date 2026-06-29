{
  lib,
  mylib,
  ...
}: {
  imports = mylib.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    type = lib.types.str;
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
  };
}
