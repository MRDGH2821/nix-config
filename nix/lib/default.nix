{
  inputs ? {},
  lib ? inputs.nixpkgs.lib,
  ...
}: let
  autoImport = import ./auto-import.nix {inherit lib;};
  domainBuilder = import ./domain-builder.nix;
  rcloneMounts = import ./rclone-mounts.nix;
in {
  inherit autoImport;
  inherit (autoImport) autoImportModules;
  inherit (autoImport) autoImportFolders;
  inherit domainBuilder;
  inherit rcloneMounts;
}
