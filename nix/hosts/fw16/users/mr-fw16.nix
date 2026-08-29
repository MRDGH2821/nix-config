{inputs, ...}: {
  home = {
    homeDirectory = "/home/mr-fw16";
    # Real Fedora login on the Framework 16 (not "mr-nix").
    username = "mr-fw16";
  };
  imports = [
    inputs.self.homeModules.common
    inputs.self.homeModules.mr-nix
  ];
  # Home Manager running on Fedora, not NixOS.
  targets.genericLinux.enable = true;
}
