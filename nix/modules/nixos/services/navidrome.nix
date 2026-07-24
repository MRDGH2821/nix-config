{
  config,
  lib,
  mylibFor,
  pkgs,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
  rclone-navidrome = "/mnt/rclone/navidrome";
  mount-options = "ro";
  music-folder = mylib.rcloneMount {
    folderName = "Music";
    mountPoint = "${rclone-navidrome}/Music";
    options = mount-options;
    remoteName = "pcloud-personal";
  };
  kirtan-folder = mylib.rcloneMount {
    folderName = "Kirtans";
    mountPoint = "${rclone-navidrome}/Kirtans";
    options = mount-options;
    remoteName = "pcloud-personal";
  };
in {
  imports = [
    music-folder
    kirtan-folder
  ];
  services.navidrome = {
    enable = false;
    openFirewall = true;
    settings = {
      BaseUrl = "https://navidrome.${config.networking.baseDomain}";
      MusicFolder = rclone-navidrome;
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
