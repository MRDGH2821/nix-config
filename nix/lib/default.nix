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
    # Close over config once — callers use mkUrl "svc" true, not pass baseDomain.
    # Wire via: `_module.args = flake.lib.mkDomainHelpers { inherit config; };`
    # or `inherit ((flake.lib.mkDomainHelpers { inherit config; })) mkUrl;`
    mkDomainHelpers = {config}: {
      mkSubdomain = subdomain: "${subdomain}.${config.networking.baseDomain}";
      mkUrl = subdomain: secure: let
        protocol =
          if secure
          then "https"
          else "http";
      in "${protocol}://${subdomain}.${config.networking.baseDomain}";
    };
  }
