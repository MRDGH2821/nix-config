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
        bun
        cocogitto
        compose2nix
        copier
        git
        git-agecrypt
        git-credential-oauth
        glab
        just
        just-lsp
        lazygit
        nil
        nixd
        repgrep
        ripgrep
        sops
        ssh-to-age
        uv
        # keep-sorted end
      ]
      ++ [nixos-cli];
  }
