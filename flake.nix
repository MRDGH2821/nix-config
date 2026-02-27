{
  description = "NixOS Homelab Configuration with Development Environment";
  inputs = {
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    authentik-nix.inputs.nixpkgs.follows = "nixpkgs";
    authentik-nix.url = "github:nix-community/authentik-nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.url = "github:aksiksi/compose2nix";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-cli.url = "github:nix-community/nixos-cli";
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
    authentik-nix,
    compose2nix,
    nixos-cli,
    sops-nix,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        alejandra.packages.${system}.default
        compose2nix.packages.${system}.default
        deno
        git-agecrypt
        just
        just-formatter
        just-lsp
        moreutils
        nil
        nixd
        nixfmt
        nixos-cli.packages.${system}.default
        nixos-rebuild
        nixpkgs-fmt
        nixpkgs-review
        sops
        ssh-to-age
      ];
      shellHook = ''
        echo "Welcome to the nix-config development environment!"
        echo "Available tools: nixd, compose2nix, deno, sops, age, ssh-to-age"
        git-agecrypt init
      '';
    };
    nixosConfigurations = {
      home-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit self;};
        modules = [
          ./nix/hosts/home-lab
          sops-nix.nixosModules.sops
          authentik-nix.nixosModules.default
        ];
      };
    };
  };
}
