_: {
  lib,
  mylib,
  ...
}: {
  imports = mylib.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
    type = lib.types.str;
  };
}
