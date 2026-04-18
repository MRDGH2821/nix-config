{
  imports = [
    ../../system-modules/container-services
    ../../system-modules/features
    ../../system-modules/fixes
    ../../system-modules/services
    ../../system-modules/shell
    ../../vars
    ./configuration.nix
    ./hardware-configuration.nix
    ./modules
    ./secrets/agecrypt/duckdns-domain.nix
    ./secrets/agecrypt/smtp.nix
  ];
}
