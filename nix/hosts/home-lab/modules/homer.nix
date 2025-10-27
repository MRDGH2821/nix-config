{config, ...}: {
  services.homer = {
    enable = false;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
    };
    virtualHost = {
      caddy.enable = false;
      nginx.enable = false;
      # domain = config.networking.baseDomain;
    };
  };
}
