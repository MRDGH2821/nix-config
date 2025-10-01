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
      sops # SOPS tool for encryption/decryption
      age # Age encryption tool
      ssh-to-age # Convert SSH keys to age keys
      sopsModule
      # sops-nix.nixosModules.sops
    ]
  );

  shellHook = ''
    echo "Welcome to the nix-config development environment!"
  '';
}
