{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;
  virtualisation.oci-containers.containers."hermes-workspace-hermes-workspace" = {
    environmentFile = config.sops.secrets.hermes-workspace.path;
  };
}
