{
  config,
  lib,
  pkgs,
  ...
}: let
  mylib = import ../../mylib/rclone-mounts.nix {inherit pkgs lib config;};
  rclone-jellyfin = "/mnt/rclone/jellyfin";
  mount-options = "ro";
  music-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Music";
    mountPoint = "${rclone-jellyfin}/Music";
    options = mount-options;
  };
  kirtan-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Kirtans";
    mountPoint = "${rclone-jellyfin}/Kirtans";
    options = mount-options;
  };
in {
  imports = [
    music-folder
    kirtan-folder
  ];
  services.jellyfin = {
    enable = true;
  };
}
