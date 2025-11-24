{pkgs}: {
  imports = [
    ../../modules/features/system-packages.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.openssh.enable = true;

  programs.ssh.startAgent = true;

  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
    hostName = "test-bed";
  };
  services.automatic-timezoned.enable = true;
}
