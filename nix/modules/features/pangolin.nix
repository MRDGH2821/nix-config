{ pkgs }:
{
  environment.system-packages = with pkgs; [
    fosrl-pangolin
  ];
}
