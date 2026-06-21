{
  config,
  lib,
  pkgs,
  ...
}: let
  mylib = import ../../mylib/rclone-mounts.nix {inherit pkgs lib config;};
  rclone-kpxc = "/mnt/rclone/kpxc";
  mount-options = "rw";
  keepassxc-folder = mylib.rcloneMount {
    remoteName = "pcloud-personal";
    folderName = "Keepass";
    mountPoint = "${rclone-kpxc}/Keepass";
    options = mount-options;
  };
in {
  imports = [
    keepassxc-folder
  ];
  services.desktopManager.plasma6.enable = true;

  services.openssh.enable = true;
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
    keepassxc
  ];

  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
