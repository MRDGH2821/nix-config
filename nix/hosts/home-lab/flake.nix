{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  outputs = {
    nixpkgs,
    sops-nix,
    ...
  }: {
    nixosConfigurations.home-lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./default.nix
      ];
    };
  };
}
