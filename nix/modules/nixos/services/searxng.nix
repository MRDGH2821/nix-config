{config, ...}: {
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets.searxng.path;
    openFirewall = true;
    redisCreateLocally = true;
    settings.server = {
      base_url = "https://searxng.${config.networking.baseDomain}";
      port = 7100;
      secret_key = "$SEARXNG_SECRET";
    };
  };
}
