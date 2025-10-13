{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  outputs = {
    self,
    nixpkgs,
    sops-nix,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    mk_scalpel = {
      matchers,
      source,
      destination,
      user ? null,
      group ? null,
      mode ? null,
    }:
      pkgs.callPackage ./../../packages/scalpel.nix {
        inherit matchers source destination user group mode;
      };

    nixosModules.scalpel = import ./../../modules/scalpel {inherit self;};
    nixosModule = self.nixosModules.scalpel;
    nixosConfigurations = let
      base-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          ./default.nix
        ];
      };
    in {
      home-lab = base-lab.extendModules {
        modules = [
          self.nixosModules.scalpel
          ./../../modules/scalpel/pangolin-scalpel.nix
        ];
        specialArgs = {
          prev = base-lab;
        };
      };
    };
  };
}
