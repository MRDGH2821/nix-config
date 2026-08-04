{config, ...}: {
  my.rclone.mounts = {
    navidrome-kirtan = {
      folderName = "Kirtans";
      mountPoint = "/mnt/rclone/navidrome/Kirtans";
      options = "ro";
      remoteName = "pcloud-personal";
    };
    navidrome-music = {
      folderName = "Music";
      mountPoint = "/mnt/rclone/navidrome/Music";
      options = "ro";
      remoteName = "pcloud-personal";
    };
  };
  services.navidrome = {
    enable = false;
    openFirewall = true;
    settings = {
      BaseUrl = "https://navidrome.${config.networking.baseDomain}";
      MusicFolder = "/mnt/rclone/navidrome";
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
