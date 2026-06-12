{
  config,
  lib,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
  hermesStateDir = config.services.hermes-agent.stateDir;
in {
  imports = autoImportLib.autoImportModules ./.;

  config = lib.mkIf config.services.hermes-agent.enable {
    virtualisation.oci-containers.containers.hermes-webui = {
      environment = {
        HERMES_WEBUI_HOST = "0.0.0.0";
        HERMES_WEBUI_PORT = "8787";
        HERMES_WEBUI_STATE_DIR = "/home/hermeswebui/.hermes/webui";
        HERMES_WEBUI_GATEWAY_BASE_URL = "http://127.0.0.1:8642";
      };
      volumes = [
        "${hermesStateDir}/.hermes:/home/hermeswebui/.hermes:rw"
        "${hermesStateDir}/current-package:/home/hermeswebui/.hermes/hermes-agent:ro"
        "${hermesStateDir}/workspace:/workspace:rw"
      ];
    };

    systemd.services."podman-hermes-webui" = {
      after = ["hermes-agent.service"];
      requires = ["hermes-agent.service"];
      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
    };
  };
}
