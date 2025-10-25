{
  imports = [
    ./secrets/agecrypt/domain.nix
    ./acme.nix
    ./sops.nix
    ../../modules/features
    ../../modules/fixes
    ../../modules/services
    ../../vars/default.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
