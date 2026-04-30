{
  description = "NixOS Homelab Configuration with Development Environment";
  inputs = {
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    authentik-nix.url = "github:nix-community/authentik-nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.url = "github:aksiksi/compose2nix";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent";
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
    hermes-agent,
    nixos-cli,
    sops-nix,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    formatter.${system} = pkgs.treefmt;
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        alejandra.packages.${system}.default
        bun
        cachix
        compose2nix.packages.${system}.default
        git-agecrypt
        just
        just-formatter
        just-lsp
        libxml2
        moreutils
        nil
        nixd
        nixfmt
        nixos-cli.packages.${system}.default
        nixos-rebuild
        nixpkgs-fmt
        nixpkgs-review
        prettypst
        shfmt
        sops
        ssh-to-age
        treefmt
        uv
        yq-go
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
        specialArgs = {
          inherit
            self
            authentik-nix
            hermes-agent
            sops-nix
            ;
        };
        modules = [
          ./nix/hosts/home-lab
          authentik-nix.nixosModules.default
          hermes-agent.nixosModules.default
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}
