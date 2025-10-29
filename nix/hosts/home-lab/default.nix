{
  imports = [
    ../../modules/container-services
    ../../modules/features
    ../../modules/fixes
    ../../modules/services
    ../../modules/shell
    ../../vars
    ./configuration.nix
    ./hardware-configuration.nix
    ./modules
    ./secrets/agecrypt/duckdns-domain.nix
    ./secrets/agecrypt/smtp.nix
  ];
}
