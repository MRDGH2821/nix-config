{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    {
      nixpkgs,
      ...
    }:
    {
      nixosConfigurations.home-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./default.nix
        ];
      };
    };
}
