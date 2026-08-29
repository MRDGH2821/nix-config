{inputs, ...}: {
  home.username = "mr-nix";
  imports = [
    inputs.self.homeModules.common
    inputs.self.homeModules.mr-nix
  ];
}
