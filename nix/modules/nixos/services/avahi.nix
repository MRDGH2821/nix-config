{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    avahi
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
    publish = {
      addresses = true; # Broadcast IP addresses
      enable = true;
      workstation = true; # Advertise this machine as a workstation
    };
  };
}
