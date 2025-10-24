{
  description = "NixOS Homelab Configuration with Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        alejandra.packages.${system}.default
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
  };
}
