{
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/features/docker.nix
    ../../modules/features/ssh.nix
    ../../packages/default.nix
    ../../vars/default.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;

  programs.ssh.startAgent = true;
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
    hostName = "home-lab";
  };

  system.stateVersion = "25.05";
}
