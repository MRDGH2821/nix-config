{
  description = "NixOS Homelab Configuration with Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    alejandra.url = "github:kamadorueda/alejandra";
    authentik-nix.url = "github:nix-community/authentik-nix";
    authentik-nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
    compose2nix.url = "github:aksiksi/compose2nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-cli.url = "github:nix-community/nixos-cli";
    nixos-cli.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
    treefmt.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "nix";
      systems = ["x86_64-linux"];
      nixpkgs.config.allowUnfree = true;
    };
}
