{pkgs, ...}: let
  sshKeys = import ../../keys/ssh-keys.nix;
in {
  environment.systemPackages = with pkgs; [
    openssh
  ];
  # configures the network interface(include wireless) via `nmcli` & `nmtui`
  networking.networkmanager.enable = true;
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
