{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    waypipe
    libva-utils
  ];
  hardware.graphics.enable = true;
  # Waypipe forwards Wayland apps over SSH (install waypipe on your local machine too).
  # Example: waypipe --video h264 ssh mr-nix@home-lab kitty
  services.openssh.settings = {
    AllowStreamLocalForwarding = "yes";
    StreamLocalBindUnlink = "yes";
  };
}
