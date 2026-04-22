{
  config,
  pkgs,
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
    addToSystemPackages = true;
    container = {
      enable = true;
      hostUsers = ["mr-nix"];
      backend = "podman";
    };
    stateDir = hermesStateDir;
    environmentFiles = [hermesEnvFile];
    settings.model.default = "nvidia/nemotron-3-super-120b-a12b:free";
  };
  environment.systemPackages = with pkgs; [
    python313Packages.mautrix
    python313Packages.python-olm
    olm
  ];
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
