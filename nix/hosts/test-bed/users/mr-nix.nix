{inputs, ...}: {
  home.username = "mr-nix";
  imports = [
    inputs.self.homeModules.common
  ];
}
