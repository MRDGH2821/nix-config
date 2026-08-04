{
  hostName ? "home-lab",
  inputs,
  ...
}: let
  mylib = import ../../lib {inherit (inputs.nixpkgs) lib;};
in {
  class = "nixos";
  value = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ./configuration.nix
      ./hardware-configuration.nix
      ./secrets/agecrypt/smtp.nix
      ./secrets/agecrypt/duckdns-domain.nix
      ./modules
      inputs.self.nixosModules.vars
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
        ;
      flake = inputs.self;
    };
  };
}
