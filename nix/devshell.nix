{
  inputs,
  pkgs,
  ...
}: let
  pre-commit-check = import ./checks/pre-commit-check.nix {inherit inputs pkgs;};
  # Flake-style package (not in nixpkgs). See:
  # https://nix-community.github.io/nixos-cli/installation.html
  nixos-cli = inputs.nixos-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
  pkgs.mkShell {
    inherit (pre-commit-check) shellHook;
    packages = with pkgs;
      [
        # keep-sorted start
        compose2nix
        git-agecrypt
        just
        just-lsp
        nil
        nixd
        sops
        ssh-to-age
        bun
        cocogitto
        copier
        git
        git-credential-oauth
        glab
        lazygit
        nil
        nixd
        repgrep
        ripgrep
        uv
        # keep-sorted end
      ]
      ++ [nixos-cli];
    
  }
