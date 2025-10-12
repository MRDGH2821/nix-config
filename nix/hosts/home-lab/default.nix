{
  imports = [
    ../../modules/features
    ../../modules/fixes
    ./sops.nix
    ../../modules/services
    ../../vars/default.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
