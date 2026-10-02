{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [5432];
  services = {
    postgresql = {
      authentication = ''
        #type database  DBuser  auth-method
        local all       all     trust
        host  all       all     0.0.0.0/0  scram-sha-256
        host  all       all     ::/0       scram-sha-256
      '';
      enable = true;
      enableTCPIP = true;
      package = pkgs.postgresql_17;
    };
    postgresqlBackup = {
      backupAll = true;
      enable = true;
      location = "${config.persistent_storage}/pg_backup/";
    };
  };
}
