{flake, ...}: {
  imports = [
    flake.modules.home.common
    flake.modules.home.mr-nix
  ];
}
