{ pkgs, ... }:
{
  services.avahi = {
    enable = true;
    openFirewall = true;

  };

  environment.systemPackages = with pkgs; [
    avahi
  ];
}
