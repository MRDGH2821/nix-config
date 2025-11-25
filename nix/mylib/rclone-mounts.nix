# Source: https://blog.emillon.org/posts/2025-06-02-using-rclone-mount-with-systemd-on-nixos.html
{
  pkgs,
  lib,
  config,
  ...
}: {
  # Create an rclone mount with systemd
  # Example usage:
  # mylib.rcloneMount {
  #   mountPoint = "/mnt/rclone/my-remote";
  #   remoteName = "my-remote";
  #   configFile = config.sops.secrets.rclone.path;
  #   options = "_netdev,args2env,allow_other,vfs-cache-mode=full";
  # }
  rcloneMount = {
    remoteName,
    folderName ? "/",
    mountPoint ? "/mnt/rclone/${remoteName}/${folderName}",
    configFile ? config.sops.secrets.rclone.path,
    options ? "",
  }: {
    environment.systemPackages = with pkgs; [
      rclone
    ];
    systemd.mounts = lib.singleton {
      where = mountPoint;
      what = "${remoteName}:${folderName}";
      type = "rclone";
      options = "_netdev,args2env,allow_other,vfs-cache-mode=full,${options},config=${configFile}";
    };
    systemd.automounts = lib.singleton {
      where = mountPoint;
      wantedBy = ["multi-user.target"];
    };
  };
}
