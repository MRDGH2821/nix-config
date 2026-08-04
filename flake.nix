{
  description = "NixOS Homelab Configuration with Development Environment";
  inputs = {
    alejandra = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:kamadorueda/alejandra";
    };
    authentik-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/authentik-nix";
    };
    blueprint = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/blueprint";
    };
    compose2nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:aksiksi/compose2nix";
    };
    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
    hermes-agent = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:NousResearch/hermes-agent";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    nixos-cli = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-cli";
    };
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    pedantix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:swarsel/pedantix/v1.1.0";
    };
    smt = {
      inputs = {
        blueprint.follows = "blueprint";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
        pedantix.follows = "pedantix";
        treefmt.follows = "treefmt";
      };
      url = "github:MRDGH2821/Sort-Markdown-Tables";
    };
    sops-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };
    treefmt = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };
  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
      prefix = "nix";
    };
}
