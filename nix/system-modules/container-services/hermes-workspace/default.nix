{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;
  virtualisation.oci-containers.containers."hermes-workspace-hermes-workspace" = {
    environmentFiles = [config.sops.secrets.hermes-workspace.path];
    environment = {
      HERMES_API_URL = "http://127.0.0.1:8642";
      # HERMES_DASHBOARD_URL = "http://127.0.0.1:9119";
      PORT = "3100";
    };
  };

  systemd.services."podman-hermes-workspace-hermes-workspace" = {
    after = lib.mkAfter ["hermes-agent.service"];
    requires = lib.mkAfter ["hermes-agent.service"];
  };
}
