{config, ...}: {
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
    environmentFiles = [config.sops.secrets.hermes-env.path];
    extraArgs = ["run"];
    stateDir = "${config.persistent_storage}/hermes-agent";
  };
  virtualisation.docker.enable = false;
}
