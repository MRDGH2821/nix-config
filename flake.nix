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
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nil
          compose2nix
          deno
          sops
          age
          ssh-to-age
          nixpkgs-fmt
          nixpkgs-review
          alejandraPkg
        ];
        shellHook = ''
          echo "Welcome to the nix-config development environment!"
          echo "Available tools: nil, compose2nix, deno, sops, age, ssh-to-age"
        '';
      };
    });
}
