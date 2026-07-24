{pkgs, ...}: {
  imports = [];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.openssh.enable = true;
  services.automatic-timezoned.enable = true;

  programs.ssh.startAgent = true;

  networking.networkmanager.enable = true;
  networking.hostName = "test-bed";

  system.stateVersion = "25.05";
}
