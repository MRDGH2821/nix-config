{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fosrl-pangolin
  ];
  services.pangolin.openFirewall = true;
  services.pangolin.enable = true;
}
