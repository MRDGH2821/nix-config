{config, ...}: {
  sops.templates."searxng.env" = {
    content = ''
      SEARXNG_SECRET=${config.sops.placeholder.searxngSecret}
    '';
  };
  services.searx = {
    domain = "https://searxng.${config.networking.baseDomain}";
    enable = true;
    redisCreateLocally = true;
    openFirewall = true;
    environmentFile = config.sops.templates."searxng.env".path;
    settings = {
      server = {
        port = 7000;
        secret_key = "$SEARXNG_SECRET";
      };
    };
  };
}
