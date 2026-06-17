{config}: {
  services.searx = {
    domain = "https://searxng.${config.networking.baseDomain}";
    enable = true;
    redisCreateLocally = true;
  };
}
