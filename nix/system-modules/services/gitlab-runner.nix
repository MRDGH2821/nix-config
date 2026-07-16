{config, ...}: {
  services.gitlab-runner = {
    enable = true;
    clear-docker-cache.enable = true;
    services = {
      an-runner = {
        executor = "docker";
        dockerImage = "alpine:latest";
        authenticationTokenConfigFile = config.sops.secrets.glr-an.path;
        dockerVolumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        dockerDisableCache = false;
      };
    };
  };
}
