# VM-only graphical sandbox for previewing the mr-fw16 Home Manager layout.
# Boot with: just test-bed-vm-run
{
  flake,
  inputs,
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
    ./modules

    # Dev-friendly system layer only — no homelab services, secrets, or containers.
    ../../modules/nixos/features/dev-packages.nix
    ../../modules/nixos/features/direnv.nix
    ../../modules/nixos/features/git.nix
    ../../modules/nixos/features/home-manager.nix
    ../../modules/nixos/features/system-packages.nix
  ];
  networking = {
    hostName = "test-bed";
    networkmanager.enable = true;
  };
  nix.settings.allowed-users = [
    "@wheel"
    "mr-fw16"
  ];
  programs.ssh.startAgent = true;
  services = {
    automatic-timezoned.enable = true;
    openssh.enable = true;
  };
  system.stateVersion = "25.05";
}
