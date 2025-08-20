{
  imports = [
    ../../modules/features/avahi.nix
    ../../modules/features/direnv.nix
    ../../modules/features/docker.nix
    ../../modules/features/ssh.nix
    ../../modules/features/system-packages.nix
    ../../modules/fixes/log-rotation.nix
    ../../modules/services/stirling-pdf.nix
    ../../vars/default.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];
}
