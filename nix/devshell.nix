{
  inputs,
  pkgs,
  ...
}: let
  pre-commit-check = import ./checks/pre-commit-check.nix {inherit inputs pkgs;};
in
  pkgs.mkShell {
    inherit (pre-commit-check) shellHook;
    packages = with pkgs; [
      nil
      nixd
      sops
      just
      just-lsp
      git-agecrypt
    ];
  }
