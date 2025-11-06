{config, ...}: {
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      MusicFolder = "${config.persistent_storage}/Music/";
      BaseUrl = "https://navidrome.${config.networking.baseDomain}";
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
