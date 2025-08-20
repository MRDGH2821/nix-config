{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        shellHook = ''
          echo "Welcome to the nix-config development environment!"
        '';
      };
    };
}
