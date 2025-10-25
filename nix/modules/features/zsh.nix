{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.zimfw
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
}
