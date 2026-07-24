# Source: https://blog.emillon.org/posts/2025-06-02-using-rclone-mount-with-systemd-on-nixos.html
{
  config,
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
    environment.systemPackages = [pkgs.rclone];
    systemd = {
      automounts = [
        {
          wantedBy = ["multi-user.target"];
          where = mountPoint;
        }
      ];
      mounts = [
        {
          options = "_netdev,args2env,allow_other,vfs-cache-mode=full,${options},config=${configFile}";
          type = "rclone";
          what = "${remoteName}:${folderName}";
          where = mountPoint;
        }
      ];
    };
  };
}
