{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
  ];
  # KeePassXC is installed and autostarted via homeModules.mr-nix (Secret Service).
  # KWallet PAM would race KeePassXC for secrets — disable unlock helpers on this host.
  hardware.graphics.enable = true;
  my.rclone.mounts.keepassxc = {
    folderName = "Keepass";
    mountPoint = "/mnt/rclone/kpxc/Keepass";
    options = "rw";
    remoteName = "pcloud-personal";
  };
  security.pam.services = {
    login.kwallet.enable = lib.mkForce false;
    sddm.kwallet.enable = lib.mkForce false;
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
