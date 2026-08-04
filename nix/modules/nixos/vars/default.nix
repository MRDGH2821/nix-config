{flake, ...}: let
  lib = flake.inputs.nixpkgs.lib;
  auto = import ../../../lib/auto-import.nix {inherit lib;};
in {
  imports = auto.autoImportModules ./.;
  options.persistent_storage = lib.mkOption {
    default = "/etc/nixos/persist";
    description = "Path to persistent storage";
    type = lib.types.str;
  };
}
