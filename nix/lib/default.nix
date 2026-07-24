{
  inputs ? {},
  lib ? inputs.nixpkgs.lib,
  ...
}: let
  autoImport = import ./auto-import.nix {inherit lib;};
in {
  inherit autoImport;
  inherit (autoImport) autoImportModules autoImportFolders;
  domainBuilder = import ./domain-builder.nix;
  rcloneMounts = import ./rclone-mounts.nix;
}
