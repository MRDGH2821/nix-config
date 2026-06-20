{
  pkgs,
  ...
}: {

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    # Required so non-root users are allowed to use the above substituter/keys.
    # Use @wheel for all sudo users, or list your username explicitly.
    trusted-users = ["root" "@wheel" "mr-nix"];
  };
  
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
