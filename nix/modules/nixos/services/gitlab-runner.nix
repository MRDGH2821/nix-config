{config, ...}: {
  services.gitlab-runner = {
    clear-docker-cache.enable = true;
    enable = true;
    services.an-runner = {
      authenticationTokenConfigFile = config.sops.secrets.glr-an.path;
      dockerDisableCache = false;
      dockerImage = "alpine:latest";
      dockerVolumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      executor = "docker";
    };
    settings.concurrent = 3;
  };
}
