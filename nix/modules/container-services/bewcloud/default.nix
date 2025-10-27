{
  config,
  lib,
  self,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;
  virtualisation.oci-containers.containers."bewcloud-website" = {
    volumes = lib.mkAfter [
      "${self.outPath}/nix/modules/container-services/bewcloud/bewcloud.env.config.ts:/app/bewcloud.config.ts:rw"
    ];
    environmentFiles = [
      config.sops.secrets.bewcloud.path
    ];
  };
}
