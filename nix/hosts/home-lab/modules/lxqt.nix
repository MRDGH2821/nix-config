{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # 1. Enable the LXQt Desktop Manager
  services.desktopManager.lxqt.enable = true;

  # 2. Enable Labwc as the pure Wayland backend window manager
  programs.labwc.enable = true;

  # 3. Minimize installation footprint (Strip legacy X11 desktop wrappers)
  services.xserver.enable = false;

  # 4. Essential network and headless tools
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    waypipe # The data pipe to transport graphics
    lxqt.lxqt-session # Explicitly ensure session manager binary is tracked
    zed-editor
  ];

  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
