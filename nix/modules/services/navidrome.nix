{config, ...}: {
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      MusicFolder = "/home/mr-nix/Music";
      BaseUrl = "navidrome.${config.networking.baseDomain}";
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
