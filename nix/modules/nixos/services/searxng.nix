{config, ...}: {
  services.searx = {
    enable = true;
    redisCreateLocally = true;
    openFirewall = true;
    environmentFile = config.sops.secrets.searxng.path;
    settings.server = {
      port = 7100;
      secret_key = "$SEARXNG_SECRET";
      base_url = "https://searxng.${config.networking.baseDomain}";
    };
  };
}
