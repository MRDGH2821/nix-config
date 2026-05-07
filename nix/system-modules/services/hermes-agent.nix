{
  config,
  pkgs,
  # lib,
  ...
}: let
  hermesStateDir = "${config.persistent_storage}/hermes-agent";
  hermesEnvFile = config.sops.secrets.hermes-env.path;
in {
  security.sudo.extraRules = [
    {
      users = ["mr-nix"];
      commands = [
        {
          command = "/run/current-system/sw/bin/podman";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
  virtualisation.docker.enable = false;
  services.hermes-agent = {
    enable = true;
    extraArgs = ["run"];
    addToSystemPackages = true;
    container = {
      enable = true;
      hostUsers = ["mr-nix"];
      backend = "podman";
    };
    stateDir = hermesStateDir;
    environmentFiles = [hermesEnvFile];
    settings.model.default = "nvidia/nemotron-3-super-120b-a12b:free";
    extraPackages = with pkgs; [
      python313Packages.mautrix
      python313Packages.python-olm
      olm
    ];
  };
  # environment.systemPackages = with pkgs; [
  # ];
  # systemd.services.hermes-dashboard = {
  #   after = ["hermes-agent.service"];
  #   serviceConfig = {
  #     EnvironmentFiles = [hermesEnvFile];
  #     ExecStart = "${lib.getExe config.services.hermes-agent.package} dashboard";
  #   };
  # };
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
