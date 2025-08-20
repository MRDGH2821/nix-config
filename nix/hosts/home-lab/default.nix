{
  imports = [
    ../../modules/features/avahi.nix
    ../../modules/features/docker.nix
    ../../modules/features/ssh.nix
    ../../modules/features/system-packages.nix
    ../../vars/default.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
