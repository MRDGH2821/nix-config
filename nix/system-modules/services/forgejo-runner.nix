{
  pkgs,
  config,
  ...
}: {
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      default = {
        enable = true;
        name = "default";
        url = "https://git.${config.networking.baseDomain}";
        tokenFile = config.sops.secrets.fjr-default.path;
        labels = [
          "ubuntu-latest:docker://node:22-bookworm"
          "ubuntu-22.04:docker://node:22-bookworm"
        ];
      };
    };
  };
}
