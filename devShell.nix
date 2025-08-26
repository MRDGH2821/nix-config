{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nil # Nix Language Server
    compose2nix
    deno
  ];

  shellHook = ''
    echo "Welcome to the nix-config development environment!"
  '';
}
