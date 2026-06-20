{
  inputs,
  pkgs,
  ...
}: let
  hypr-pkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hypr-plugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in {
  wayland.windowManager.hyprland = {
    enable = true;
    # set the flake package
    package = hypr-pkgs.hyprland;
    portalPackage =
      hypr-pkgs.xdg-desktop-portal-hyprland;
    plugins = [
      hypr-plugins.hyprbars
    ];
  };
}
