{
  inputs ? {},
  lib ? inputs.nixpkgs.lib,
  ...
}: let
  autoImport = import ./auto-import.nix {inherit lib;};
in
  autoImport
  // {
    inherit (autoImport) autoImportModules autoImportFolders;
    mkSubdomain = baseDomain: subdomain: "${subdomain}.${baseDomain}";
    mkUrl = baseDomain: subdomain: secure: let
      protocol =
        if secure
        then "https"
        else "http";
    in "${protocol}://${subdomain}.${baseDomain}";
  }
