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
    ./hardware-configuration.nix
    ../home-lab/modules/sops.nix
    ../home-lab/modules/acme.nix

    flake.modules.nixos.features
    flake.modules.nixos.services
    flake.modules.nixos.fixes
    flake.modules.nixos.container-services
    flake.modules.nixos.vars

    inputs.sops-nix.nixosModules.sops
    inputs.authentik-nix.nixosModules.default
    inputs.hermes-agent.nixosModules.default
  ];
  networking = {
    hostName = "test-bed";
    networkmanager.enable = true;
  };
  programs.ssh.startAgent = true;
  services = {
    automatic-timezoned.enable = true;
    openssh.enable = true;
  };
  system.stateVersion = "25.05";
}
