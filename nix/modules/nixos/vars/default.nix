{flake, ...}: let
  inherit (flake.inputs.nixpkgs) lib;
in {
  imports = flake.lib.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
    type = lib.types.str;
  };
}
