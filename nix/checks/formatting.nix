{
  inputs,
  pkgs,
  ...
}:
(import ../formatter.nix {inherit inputs pkgs;}).check
