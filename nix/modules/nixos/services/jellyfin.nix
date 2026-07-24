{
  config,
  lib,
  mylibFor,
  pkgs,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
  rclone-jellyfin = "/mnt/rclone/jellyfin";
  mount-options = "ro";
  music-folder = mylib.rcloneMount {
    folderName = "Music";
    mountPoint = "${rclone-jellyfin}/Music";
    options = mount-options;
    remoteName = "pcloud-personal";
  };
  kirtan-folder = mylib.rcloneMount {
    folderName = "Kirtans";
    mountPoint = "${rclone-jellyfin}/Kirtans";
    options = mount-options;
    remoteName = "pcloud-personal";
  };
in {
  imports = [
    music-folder
    kirtan-folder
  ];
  services.jellyfin.enable = true;
}
