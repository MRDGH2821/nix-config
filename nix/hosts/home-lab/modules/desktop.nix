{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
    keepassxc
  ];
  hardware.graphics.enable = true;
  imports = [../../../modules/nixos/features/rclone-mounts.nix];
  my.rclone.mounts.keepassxc = {
    folderName = "Keepass";
    mountPoint = "/mnt/rclone/kpxc/Keepass";
    options = "rw";
    remoteName = "pcloud-personal";
  };
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
