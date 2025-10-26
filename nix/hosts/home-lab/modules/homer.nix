{config, ...}: {
  services.homer = {
    enable = true;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
    };
    virtualHost = {
      caddy.enable = config.services.caddy.enable;
      nginx.enable = config.services.nginx.enable;
    };
  };
}
