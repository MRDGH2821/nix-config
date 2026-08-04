{
  my.rclone.mounts = {
    jellyfin-kirtan = {
      folderName = "Kirtans";
      mountPoint = "/mnt/rclone/jellyfin/Kirtans";
      options = "ro";
      remoteName = "pcloud-personal";
    };
    jellyfin-music = {
      folderName = "Music";
      mountPoint = "/mnt/rclone/jellyfin/Music";
      options = "ro";
      remoteName = "pcloud-personal";
    };
  };
  services.jellyfin.enable = true;
}
