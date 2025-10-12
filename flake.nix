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
    pkgs = nixpkgs.legacyPackages.${system};

    # Import our custom modules
    myLib = import ./nix/mylib/auto-import.nix {inherit (pkgs) lib;};
  in {
    # Development shells
    devShells.${system} = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil # Nix Language Server
          compose2nix
          deno
          sops # SOPS tool for encryption/decryption
          age # Age encryption tool
          ssh-to-age # Convert SSH keys to age keys
          nixpkgs-fmt
          nixpkgs-review
          alejandra.defaultPackage.${system}
        ];

        shellHook = ''
          echo "Welcome to the nix-config development environment!"
          echo "Available tools: nil, compose2nix, deno, sops, age, ssh-to-age"
        '';
      };

      # Alternative shell for CI/testing
      ci = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil
          sops
          age
          ssh-to-age
        ];
      };
    };

    # Export our utility libraries for reuse
    lib = myLib;

    # Export modules for reuse in other flakes
    nixosModules = {
      homelab-features = ./nix/modules/features;
      homelab-services = ./nix/modules/services;
      homelab-fixes = ./nix/modules/fixes;
      homelab-vars = ./nix/vars;
    };
  };
}
