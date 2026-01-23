{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    compose2nix
  ];
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
