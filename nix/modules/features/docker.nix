{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    docker
    docker-buildx
    docker-compose
    compose2nix
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;
}
