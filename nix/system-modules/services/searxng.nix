{config, ...}: {
  services.searx = {
    domain = "https://searxng.${config.networking.baseDomain}";
    enable = true;
    redisCreateLocally = true;
    openFirewall = true;
    environmentFile = config.sops.secrets.searxng.path;
    settings = {
      server = {
        port = 7000;
        secret_key = "$SEARXNG_SECRET";
      };
    };
  };
}
