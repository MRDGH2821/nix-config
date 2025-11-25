{
  config,
  lib,
  pkgs,
  ...
}: let
  mylib = import ../../mylib/rclone-mounts.nix {inherit pkgs lib config;};
  rclone-navidrome = "/mnt/rclone/navidrome";
  music-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Music";
    mountPoint = "${rclone-navidrome}/Music";
  };
  kirtan-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Kirtans";
    mountPoint = "${rclone-navidrome}/Kirtans";
  };
in {
  imports = [music-folder kirtan-folder];
  services.navidrome = {
    enable = true;
    openFirewall = true;
    settings = {
      MusicFolder = rclone-navidrome;
      BaseUrl = "https://navidrome.${config.networking.baseDomain}";
      ReverseProxyUserHeader = "X-authentik-username";
    };
  };
}
