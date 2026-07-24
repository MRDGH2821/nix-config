{pkgs, ...}: let
  sshKeys = import ../keys/ssh-keys.nix;
in {
  programs.zsh.enable = true;

  users.users.mr-nix = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [sshKeys.sharedKey];
    extraGroups = [
      "docker"
      "podman"
      "networkmanager"
      "wheel"
    ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    allowed-users = [
      "@wheel"
      "mr-nix"
    ];
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
