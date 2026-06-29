{
  imports = [
    ./secrets/agecrypt/smtp.nix
    ./secrets/agecrypt/duckdns-domain.nix
    ./modules
    ./hardware-configuration.nix
    ./configuration.nix
    ../../vars
    ../../system-modules/shell
    ../../system-modules/services
    ../../system-modules/fixes
    ../../system-modules/features
    ../../system-modules/container-services
  ];
}
