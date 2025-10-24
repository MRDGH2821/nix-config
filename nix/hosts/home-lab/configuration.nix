{
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    ./sops.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
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
    hostName = "home-lab";
  };

  users.users.bose-game = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5wVbxASqs1YeVPFBzUoyNCABQFDOF0/JXxGrz2u215 Bose Game Mini PC"
    ];
  };
  nix.settings.allowed-users = [ "@wheel" "bose-game" ];
  system.stateVersion = "25.05";
}
