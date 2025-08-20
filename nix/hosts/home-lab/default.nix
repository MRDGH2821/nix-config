{
  imports = [
    ../../modules/features/docker.nix
    ../../modules/features/ssh.nix
    ../../modules/features/system-packages.nix
    ../../vars/default.nix
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
