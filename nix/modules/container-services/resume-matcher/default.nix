{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
  serviceName = "resume-matcher";
  baseDir = "${config.persistent_storage}/${serviceName}";
in {
  imports = autoImportLib.autoImportModules ./.;

  # Create volume directory hierarchy with mr-nix user as owner
  systemd.tmpfiles.rules = [
    "d ${baseDir} 0755 mr-nix users -"
    "d ${baseDir}/app 0755 mr-nix users -"
    "d ${baseDir}/app/backend 0755 mr-nix users -"
    "d ${baseDir}/app/backend/data 0755 mr-nix users -"
    "d ${baseDir}/app/backend/data/tmp 0755 mr-nix users -"
  ];

  virtualisation.oci-containers.containers."resume-matcher" = {
    environment = {
      NEXT_PUBLIC_API_URL = "http://resmapi.${config.networking.baseDomain}";
      CORS_ORIGINS = ''["http://localhost:3000","http://127.0.0.1:3000", "http://${serviceName}.${config.networking.baseDomain}", "http://resmapi.${config.networking.baseDomain}"]'';
      FRONTEND_BASE_URL = "http://${serviceName}.${config.networking.baseDomain}";
    };
  };
}
