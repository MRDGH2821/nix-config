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
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
    authentik-nix,
    compose2nix,
    nixos-cli,
    sops-nix,
    home-manager,
    nix-openclaw,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    formatter.${system} = pkgs.treefmt;
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        alejandra.packages.${system}.default
        bun
        compose2nix.packages.${system}.default
        deno
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
        specialArgs = {inherit self;};
        modules = [
          ./nix/hosts/home-lab
          sops-nix.nixosModules.sops
          authentik-nix.nixosModules.default
          home-manager.nixosModules.home-manager
        ];
      };
    };
    homeConfigurations.bose-game = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      specialArgs = {inherit nix-openclaw;};
      modules = [
        ./nix/home/users/home-lab.nix
      ];
    };
  };
}
