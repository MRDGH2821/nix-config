{
  description = "NixOS Homelab Configuration with Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    alejandra,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      myLib = import ./nix/mylib/auto-import.nix {inherit (pkgs) lib;};
      alejandraPkg =
        alejandra.packages.${system}.default or alejandra.defaultPackage.${system};
      mk_scalpel = {
        matchers,
        source,
        destination,
        user ? null,
        group ? null,
        mode ? null,
      }:
        pkgs.callPackage ./nix/packages/scalpel.nix {
          inherit matchers source destination user group mode;
        };

      nixosModules.scalpel = import ./nix/modules/scalpel {inherit self;};
      nixosModule = self.nixosModules.scalpel;
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs self; [
          nil
          compose2nix
          deno
          sops
          age
          ssh-to-age
          nixpkgs-fmt
          nixpkgs-review
          alejandraPkg
          nixos-rebuild-ng
          self.nixosModules.scalpel
          nixos-container
        ];
        shellHook = ''
          echo "Welcome to the nix-config development environment!"
          echo "Available tools: nil, compose2nix, deno, sops, age, ssh-to-age"
        '';
      };
    });
}
