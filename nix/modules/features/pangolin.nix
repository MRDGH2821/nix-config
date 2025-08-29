{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fosrl-pangolin
  ];
}
