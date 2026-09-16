{
  lib,
  pkgs,
  ...
}: {
  hardware.graphics.enable = true;
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.konsole
    tree
    zed-editor
  ];
  security.pam.services = {
    login.kwallet.enable = lib.mkForce false;
    sddm.kwallet.enable = lib.mkForce false;
  };
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
  };
  users.users.mr-fw16.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
