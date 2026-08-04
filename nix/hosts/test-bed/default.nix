{
  hostName ? "test-bed",
  inputs,
  ...
}: let
  mylib = import ../../lib {inherit (inputs.nixpkgs) lib;};
  mylibFor = args: mylib // (import ../../lib/rclone-mounts.nix args);
in {
  class = "nixos";
  value = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ./configuration.nix
      ./hardware-configuration.nix
      ../../vars
      inputs.self.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      inputs.authentik-nix.nixosModules.default
      inputs.hermes-agent.nixosModules.default
    ];
    specialArgs = {
      inherit
        inputs
        hostName
        mylib
        mylibFor
        ;
    };
  };
}
