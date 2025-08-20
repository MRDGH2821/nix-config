{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nil # Nix Language Server
  ];

  shellHook = ''
    echo "Welcome to the nix-config development environment!"
  '';
}
