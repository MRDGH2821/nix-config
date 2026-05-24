{pkgs, ...}: let
  sshKeys = import ../keys/ssh-keys.nix;
in {
  # username = "mr-nix";
  programs.zsh.enable = true;
  users.users.mr-nix = {
    openssh.authorizedKeys.keys = [
      sshKeys.sharedKey
    ];
    isNormalUser = true;
    extraGroups = [
      "docker"
      "podman"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.allowed-users = [
    "@wheel"
    "mr-nix"
  ];

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
