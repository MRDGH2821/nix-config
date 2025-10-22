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
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {system = system;};
        alejandraPkg = alejandra.packages.${system}.default or alejandra.defaultPackage.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            age
            alejandraPkg
            compose2nix
            deno
            git-agecrypt
            nil
            nixos-rebuild-ng
            nixpkgs-fmt
            nixpkgs-review
            sops
            ssh-to-age
          ];
          shellHook = ''
            echo "Welcome to the nix-config development environment!"
            echo "Available tools: nil, compose2nix, deno, sops, age, ssh-to-age"
          '';
        };
      }
    );
}
