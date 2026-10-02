{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.rclone.mounts;
in {
  config = lib.mkIf (cfg != {}) {
    environment.systemPackages = [pkgs.rclone];
    systemd = {
      automounts =
        lib.mapAttrsToList (_name: m: {
          wantedBy = ["multi-user.target"];
          where = m.mountPoint;
        })
        cfg;
      mounts =
        lib.mapAttrsToList (_name: m: {
          options = "_netdev,args2env,allow_other,vfs-cache-mode=full,${m.options},config=${m.configFile}";
          type = "rclone";
          what = "${m.remoteName}:${m.folderName}";
          where = m.mountPoint;
        })
        cfg;
    };
  };
  options.my.rclone.mounts = lib.mkOption {
    default = {};
    description = "Declarative rclone systemd mounts";
    type = lib.types.attrsOf (
      lib.types.submodule (_: {
        options = {
          configFile = lib.mkOption {
            default = config.sops.secrets.rclone.path;
            description = "Path to rclone config file";
            type = lib.types.path;
          };
          folderName = lib.mkOption {
            default = "/";
            description = "Remote folder path";
            type = lib.types.str;
          };
          mountPoint = lib.mkOption {
            description = "Local mount point";
            type = lib.types.str;
          };
          options = lib.mkOption {
            default = "";
            description = "Extra rclone mount options (comma-separated fragment)";
            type = lib.types.str;
          };
          remoteName = lib.mkOption {
            description = "rclone remote name";
            type = lib.types.str;
          };
        };
      })
    );
  };
}
