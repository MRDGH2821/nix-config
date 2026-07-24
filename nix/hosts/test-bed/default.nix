{
  inputs,
  hostName ? "test-bed",
  ...
}: let
  mylib = import ../../lib {inherit (inputs.nixpkgs) lib;};
  mylibFor = args: mylib // (import ../../lib/rclone-mounts.nix args) // (import ../../lib/domain-builder.nix {config = args.config;});
in {
  class = "nixos";
  value = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs hostName mylib mylibFor;
    };
    modules = [
      ./configuration.nix
      ./hardware-configuration.nix
      ../../vars
      ../../modules/nixos
      inputs.sops-nix.nixosModules.sops
      inputs.authentik-nix.nixosModules.default
      inputs.hermes-agent.nixosModules.default
    ];
  };
}
