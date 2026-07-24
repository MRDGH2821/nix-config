{
  lib ? inputs.nixpkgs.lib,
  inputs ? {},
  ...
}: let
  autoImport = import ./auto-import.nix {inherit lib;};
  domainBuilder = import ./domain-builder.nix;
  rcloneMounts = import ./rclone-mounts.nix;
in {
  autoImport = autoImport;
  autoImportModules = autoImport.autoImportModules;
  autoImportFolders = autoImport.autoImportFolders;
  domainBuilder = domainBuilder;
  rcloneMounts = rcloneMounts;
}
