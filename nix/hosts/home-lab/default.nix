{
  imports = [
    ../../modules/features
    ../../modules/fixes
    ../../modules/services
    ../../vars
    ./configuration.nix
    ./hardware-configuration.nix
    ./modules
    ./secrets/agecrypt/duckdns-domain.nix
    ./secrets/agecrypt/smtp.nix
  ];
}
