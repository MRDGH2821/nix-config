{ pkgs, ... }:
{
  services.avahi = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    avahi
  ];
}
