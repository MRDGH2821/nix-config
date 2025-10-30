{
  config,
  lib,
  self,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
  bewcloud_path = "${config.persistent_storage}/bewcloud";
  data-files = "${bewcloud_path}/data-files";
in {
  imports = autoImportLib.autoImportModules ./.;

  # Create necessary directories for bewcloud container
  systemd.tmpfiles.rules = [
    "d ${bewcloud_path} 0755 root root -"
    "d ${data-files} 0755 root root -"
    "d ${data-files}/.Trash 0755 root root -"
    "d ${data-files}/Photos 0755 root root -"
    "d ${data-files}/Notes 0755 root root -"
  ];

  virtualisation.oci-containers.containers."bewcloud-website" = {
    volumes = lib.mkAfter [
      "${self.outPath}/nix/modules/container-services/bewcloud/bewcloud.env.config.ts:/app/bewcloud.config.ts:rw"
    ];
    environmentFiles = [
      config.sops.secrets.bewcloud.path
    ];
  };
}
