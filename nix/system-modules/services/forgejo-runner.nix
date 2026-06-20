{
  pkgs,
  config,
  ...
}: {
  sops.templates.forgejo-runner = {
    content = ''
      TOKEN=${config.sops.placeholder.forgejo-runner-default}
    '';
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      default = {
        enable = true;
        name = config.networking.hostName;
        url = "https://git.${config.networking.baseDomain}";
        tokenFile = config.sops.templates.forgejo-runner.path;
        labels = [
          "ubuntu-latest:docker://node:22-bookworm"
          "ubuntu-22.04:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
        ];
      };
    };
  };
}
