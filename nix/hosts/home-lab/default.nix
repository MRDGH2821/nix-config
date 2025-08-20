{
  imports = [
    ../../modules/features/docker.nix
    ../../modules/features/ssh.nix
    ../../packages/default.nix
    ../../vars/default.nix
    # ./hardware-configuration.nix
    ./configuration.nix
  ];
}
