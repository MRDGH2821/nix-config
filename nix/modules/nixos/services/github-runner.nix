{config, ...}: {
  services.github-runners.runner1 = {
    enable = true;
    name = "runner1";
    tokenFile = config.sops.secrets.gh-runner1.path;
    url = "https://github.com/nixos/nixpkgs";
  };
}
