{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Development shell
      devShells.${system}.default = import ./devShell.nix {
        inherit pkgs;
        sopsModule = sops-nix.nixosModules.sops;
      };
    };
}
