{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    compose2nix
  ];
  virtualisation.podman = {
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    enable = true;
  };
}
