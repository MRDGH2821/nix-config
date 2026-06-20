{
  pkg,
  config,
  ...
}: {
  services.gitea-actions-runner = {
    package = pkg.forgejo-runner;
    instances = {
      default = {
        enable = true;
        url = "git.${config.networking.baseDomain}";
      };
    };
  };
}
