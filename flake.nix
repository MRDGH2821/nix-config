{
  description = "NixOS Homelab Configuration with Development Environment";
  inputs = {
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    alejandra.url = "github:kamadorueda/alejandra";
    authentik-nix.url = "github:nix-community/authentik-nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.url = "github:aksiksi/compose2nix";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-cli.url = "github:nix-community/nixos-cli";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    alejandra,
    authentik-nix,
    compose2nix,
    hermes-agent,
    home-manager,
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
        just-lsp
        lazygit
        libxml2
        moreutils
        nil
        nixd
        nixfmt
        nixos-anywhere
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
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.mr-nix = ./nix/hosts/home-lab/home;
          }
        ];
      };
      test-bed = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit self sops-nix;
        };
        modules = [
          ./nix/hosts/test-bed
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}
