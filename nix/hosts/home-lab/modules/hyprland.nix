{
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.displayManager.defaultSession = "hyprland-uwsm";

  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    kitty # default terminal in generated Hyprland config
    zed-editor
  ];

  users.users.mr-nix.extraGroups = [
    "audio"
    "render"
    "video"
  ];
}
