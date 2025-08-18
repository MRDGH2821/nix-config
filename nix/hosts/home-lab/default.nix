{
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ../../modules/features/ssh.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;

  environment.systemPackages =
    with pkgs;
    map lib.lowPrio [
      curl
      gitMinimal
      neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      git
      wget
      curl
    ];

  programs.ssh.startAgent = true;
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };

  system.stateVersion = "25.05";
}
