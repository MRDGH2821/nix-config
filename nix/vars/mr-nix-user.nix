{pkgs, ...}: let
  sshKeys = import ../keys/ssh-keys.nix;
in {
  nix.settings = {
    allowed-users = [
      "@wheel"
      "mr-nix"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  programs.zsh.enable = true;
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  users.users.mr-nix = {
    extraGroups = [
      "docker"
      "podman"
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [sshKeys.sharedKey];
    shell = pkgs.zsh;
  };
}
