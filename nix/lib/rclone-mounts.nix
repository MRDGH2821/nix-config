# Source: https://blog.emillon.org/posts/2025-06-02-using-rclone-mount-with-systemd-on-nixos.html
{
  config,
  lib,
  pkgs,
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
    configFile ? config.sops.secrets.rclone.path,
    folderName ? "/",
    mountPoint ? "/mnt/rclone/${remoteName}/${folderName}",
    options ? "",
    remoteName,
  }: {
    environment.systemPackages = with pkgs; [
      rclone
    ];
    systemd = {
      automounts = lib.singleton {
        wantedBy = ["multi-user.target"];
        where = mountPoint;
      };
      mounts = lib.singleton {
        options = "_netdev,args2env,allow_other,vfs-cache-mode=full,${options},config=${configFile}";
        type = "rclone";
        what = "${remoteName}:${folderName}";
        where = mountPoint;
      };
    };
  };
}
