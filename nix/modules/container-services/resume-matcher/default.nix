{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
  serviceName = "resume-matcher";
  volumePath = "${config.persistent_storage}/nix/modules/container-services/${serviceName}/app/backend/data/";
in {
  imports = autoImportLib.autoImportModules ./.;

  # Create volume directory with mr-nix user as owner
  systemd.tmpfiles.rules = [
    "d ${volumePath} 0755 mr-nix users -"
  ];

  # Ensure tmpfiles creates directory before container starts
  systemd.services."podman-${serviceName}" = {
    after = ["systemd-tmpfiles-setup.service"];
    requires = ["systemd-tmpfiles-setup.service"];
  };
}
