{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    docker
    docker-buildx
    docker-compose
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;
}
