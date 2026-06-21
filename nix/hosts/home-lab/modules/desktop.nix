{pkgs, ...}: {
  services.desktopManager.plasma6.enable = true;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    waypipe
    zed-editor
  ];

  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
