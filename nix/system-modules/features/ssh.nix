{pkgs, ...}: let
  sshKeys = import ../../keys/ssh-keys.nix;
in {
  programs.ssh.startAgent = true;

  users.users.system-recovery = {
    openssh.authorizedKeys.keys = [
      sshKeys.sharedKey
    ];
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  services.openssh.enable = true;
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };
  environment.systemPackages = with pkgs; [
    openssh
  ];
  nix.settings.allowed-users = [
    "@wheel"
    "system-recovery"
  ];
}
