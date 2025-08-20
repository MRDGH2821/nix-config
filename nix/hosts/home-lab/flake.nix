{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  outputs =
    {
      nixpkgs,
      nixos-facter-modules,
      ...
    }:
    {

      nixosConfigurations.home-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./default.nix
          # ./hardware-configuration.nix
          # ./configuration.nix
          nixos-facter-modules.nixosModules.facter
          {
            config.facter.reportPath =
              if builtins.pathExists ./bose-game-home-lab.json then
                ./bose-game-home-lab.json
              else
                throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./bose-game-home-lab.json`?";
          }
        ];
      };
    };
}
