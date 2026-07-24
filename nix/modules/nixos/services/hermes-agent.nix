{config, ...}: let
  hermesStateDir = "${config.persistent_storage}/hermes-agent";
  hermesEnvFile = config.sops.secrets.hermes-env.path;
in {
  security.sudo.extraRules = [
    {
      commands = [
        {
          command = "/run/current-system/sw/bin/podman";
          options = ["NOPASSWD"];
        }
      ];
      users = ["mr-nix"];
    }
  ];
  services.hermes-agent = {
    addToSystemPackages = true;
    container = {
      backend = "podman";
      enable = true;
      hostUsers = ["mr-nix"];
    };
    enable = true;
    environmentFiles = [hermesEnvFile];
    extraArgs = ["run"];
    stateDir = hermesStateDir;
  };
  virtualisation.docker.enable = false;
}
