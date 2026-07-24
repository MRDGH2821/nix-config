{
  config,
  lib,
  mylibFor,
  pkgs,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
  rclone-kpxc = "/mnt/rclone/kpxc";
  mount-options = "rw";
  keepassxc-folder = mylib.rcloneMount {
    folderName = "Keepass";
    mountPoint = "${rclone-kpxc}/Keepass";
    options = mount-options;
    remoteName = "pcloud-personal";
  };
in {
  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
    keepassxc
  ];
  hardware.graphics.enable = true;
  imports = [keepassxc-folder];
  services = {
    desktopManager.plasma6.enable = true;
    openssh.enable = true;
  };
  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
