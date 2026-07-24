{
  modulesPath,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  networking = {
    hostName = "home-lab";
    networkmanager.enable = true;
  };
  nix.settings.allowed-users = [
    "@wheel"
    "bose-game"
  ];
  programs.ssh.startAgent = true;
  services = {
    automatic-timezoned.enable = true;
    openssh.enable = true;
  };
  system.stateVersion = "25.05";
  users.users.bose-game = {
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5wVbxASqs1YeVPFBzUoyNCABQFDOF0/JXxGrz2u215 Bose Game Mini PC"
    ];
  };
}
