{pkgs, ...}: let
  sshKeys = import ../../keys/ssh-keys.nix;
in {
  environment.systemPackages = with pkgs; [
    openssh
  ];
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };
  nix.settings.allowed-users = [
    "@wheel"
    "system-recovery"
  ];
  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  users.users.system-recovery = {
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      sshKeys.sharedKey
    ];
  };
}
