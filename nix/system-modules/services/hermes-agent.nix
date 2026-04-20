{
  config,
  hermes-agent,
  ...
}: let
  hermesStateDir = "${config.persistent_storage}/hermes-agent";
  hermesEnvMount = "/run/secrets/hermes-env";
in {
  # Persist Hermes state on the host. Bind mounts do not remap UIDs; use a
  # liberal mode so the in-container `hermes` user can write (tighten with a
  # fixed UID if you prefer).
  systemd.tmpfiles.rules = [
    "d ${hermesStateDir} 0777 root root -"
  ];

  containers.hermes-agent = {
    autoStart = true;
    ephemeral = false;
    # Share host network so the agent can reach LLM APIs without host NAT for ve-*.
    privateNetwork = false;
    # First boot pulls the OCI image inside the guest; allow a generous start window.
    timeoutStartSec = "10min";

    bindMounts = {
      "${hermesEnvMount}" = {
        hostPath = config.sops.secrets.hermes-env.path;
        isReadOnly = true;
      };
      "/var/lib/hermes" = {
        hostPath = hermesStateDir;
        isReadOnly = false;
      };
    };

    specialArgs = {inherit hermes-agent;};

    config = {
      lib,
      hermes-agent,
      ...
    }: {
      imports = [hermes-agent.nixosModules.default];

      system.stateVersion = "25.05";

      # Hermes OCI mode (Ubuntu + bind-mounted Nix hermes binary). Matches
      # https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup
      # Podman aligns with the homelab host; Hermes defaults to Docker otherwise.
      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerSocket.enable = true;
      };
      virtualisation.docker.enable = lib.mkForce false;

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        environmentFiles = [hermesEnvMount];
        container = {
          enable = true;
          backend = "podman";
        };
      };
    };
  };
}
