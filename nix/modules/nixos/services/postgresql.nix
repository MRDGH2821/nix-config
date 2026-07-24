{
  pkgs,
  config,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    authentication = ''
      #type database  DBuser  auth-method
      local all       all     trust
      host  all       all     0.0.0.0/0  scram-sha-256
      host  all       all     ::/0       scram-sha-256
    '';
    enableTCPIP = true;
  };
  networking.firewall.allowedTCPPorts = [5432];
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "${config.persistent_storage}/pg_backup/";
  };
}
