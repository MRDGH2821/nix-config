{config, ...}: {
  sops.templates."searxng.env" = {
    content = ''
      SEARX_SECRET_KEY=${config.sops.placeholder.searxngSecret}
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
        secret_key = "$SEARX_SECRET_KEY";
      };
    };
  };
}
