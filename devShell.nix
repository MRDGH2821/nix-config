{
  pkgs,
  sopsModule ? null,
}:

pkgs.mkShell {
  buildInputs = (
    with pkgs;
    [
      nil # Nix Language Server
      compose2nix
      deno
      sopsModule
    ]
  );

  shellHook = ''
    echo "Welcome to the nix-config development environment!"
  '';
}
