{
  pkgs,
  lib,
  config,
  ...
}: let
  mountPoint = "/mnt/rclone/pcloud-personal";
  remoteName = "pcloud-personal";
  configFile = config.sops.secrets.rclone.path;
in {
  environment.systemPackages = with pkgs; [
    rclone
  ];
  systemd.mounts = lib.singleton {
    where = mountPoint;
    what = "${remoteName}:/";
    type = "rclone";
    options = "_netdev,args2env,allow_other,vfs-cache-mode=full,config=${configFile}";
  };
  systemd.automounts = lib.singleton {
    where = mountPoint;
    wantedBy = ["multi-user.target"];
  };
}
