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

  # Ensure tmpfiles creates directory before container starts (append to existing dependencies)
  systemd.services."podman-${serviceName}" = {
    after = lib.mkAfter ["systemd-tmpfiles-setup.service"];
    requires = lib.mkAfter ["systemd-tmpfiles-setup.service"];
  };
}
