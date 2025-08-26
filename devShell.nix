{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nil # Nix Language Server
    compose2nix
  ];

  shellHook = ''
    echo "Welcome to the nix-config development environment!"
  '';
}
