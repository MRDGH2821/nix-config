{config, ...}: {
  services.homer = {
    enable = true;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
    };
    virtualHost = {
      caddy.enable = true;
      nginx.enable = false;
      domain = config.networking.baseDomain;
    };
  };
}
