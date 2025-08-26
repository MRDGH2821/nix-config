{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "bewcloud" ];
    ensureUsers = [
      {
        name = "bewcloud";
        password = "fake";
        ensureDBOwnership = true;
      }
    ];
    package = pkgs.postgresql_17;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
    enableTCPIP = false;
  };
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    backupPath = "/etc/nixos/persist/pg_backup/";
  };
}
