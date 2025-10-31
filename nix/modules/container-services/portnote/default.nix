{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;

  virtualisation.oci-containers.containers."portnote-agent" = {
    environmentFiles = [
      config.sops.secrets.portnote.path
    ];
  };
  virtualisation.oci-containers.containers."portnote-web" = {
    environmentFiles = [
      config.sops.secrets.portnote.path
    ];
  };

  services.postgresql = {
    ensureDatabases = ["portnote"];
    ensureUsers = [
      {
        name = "portnote";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
}
