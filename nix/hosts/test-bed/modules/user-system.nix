{pkgs, ...}: let
  sshKeys = import ../../../keys/ssh-keys.nix;
in {
  programs.zsh.enable = true;
  security.pam.services = {
    login.u2fAuth = false;
    sudo.u2fAuth = false;
  };
  users.users = {
    mr-fw16 = {
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      initialPassword = "preview"; # betterleaks:allow — throwaway local-only VM login
      isNormalUser = true;
      openssh.authorizedKeys.keys = [sshKeys.sharedKey];
      shell = pkgs.zsh;
    };
    root.initialPassword = "preview"; # betterleaks:allow — throwaway local-only VM login
  };
}
