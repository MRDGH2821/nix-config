{
  description = "NixOS Homelab Services Collection";

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
      # Individual service modules as outputs
      nixosModules = {
        # Database services
        postgresql = import ./postgresql.nix;

        # PDF processing
        stirling-pdf = import ./stirling-pdf.nix;

        # Network services
        avahi = import ./avahi.nix;

        # Custom services
        pangolin = import ./pangolin.nix;

        # All services combined (equivalent to current default.nix)
        default =
          { lib, ... }:
          {
            imports = [
              ./postgresql.nix
              ./stirling-pdf.nix
              ./avahi.nix
              ./pangolin.nix
            ];
          };
      };

      # Service packages if any services provide custom packages
      packages.${system} = {
        # Future: custom service packages can be added here
      };

      # Development shell for service development/testing
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil
          postgresql
          docker
          docker-compose
        ];

        shellHook = ''
          echo "Homelab Services Development Environment"
          echo "Available services: postgresql, stirling-pdf, avahi, pangolin"
        '';
      };

      # Service configurations as overlays
      overlays.default = final: prev: {
        # Future: service-specific package overlays
      };
    };
}
