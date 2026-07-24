{config, ...}: {
  services.forgejo-runner = {
    connections.default = {
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
        "ubuntu-22.04:docker://node:22-bookworm"
      ];
      tokenFile = config.sops.secrets.fjr-runner-token.path;
      url = "https://git.${config.networking.baseDomain}";
      uuid = "78fd7136-1f53-4574-9fab-5e5c88e35858";
    };
    containerRuntime = "podman";
    enable = true;
  };
}
