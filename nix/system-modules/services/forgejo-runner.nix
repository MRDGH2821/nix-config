{config, ...}: {
  services.forgejo-runner = {
    enable = true;
    containerRuntime = "podman";
    connections.default = {
      url = "https://git.${config.networking.baseDomain}";
      # CHANGE ME: replace with the real runner UUID (see Task 2, Step 1).
      uuid = "00000000-0000-0000-0000-000000000000";
      tokenFile = config.sops.secrets.fjr-runner-token.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
        "ubuntu-22.04:docker://node:22-bookworm"
      ];
    };
  };
}
