{ pkgs, ... }:
{
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true; # Broadcast IP addresses
      workstation = true; # Advertise this machine as a workstation
    };
  };

  environment.systemPackages = with pkgs; [
    avahi
  ];
}
