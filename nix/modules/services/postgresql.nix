{
  pkgs,
  config,
  ...
}: {
  sops.templates."init-sql-script".content = ''
    alter user bewcloud with password '${config.sops.placeholder.bewcloud_db_pass}';
  '';

  services.postgresql = {
    enable = true;
    ensureDatabases = ["bewcloud"];
    ensureUsers = [
      {
        name = "bewcloud";
        ensureDBOwnership = true;
      }
    ];
    package = pkgs.postgresql_17;
    authentication = ''
      #type database  DBuser  auth-method
      local all       all     trust
      host  all       all     0.0.0.0/0  scram-sha-256
      host  all       all     ::/0       scram-sha-256
    '';
    enableTCPIP = true;
    initialScript = config.sops.templates."init-sql-script".path;
  };
  networking.firewall.allowedTCPPorts = [5432];
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "${config.persistant_storage}/pg_backup/";
  };
}
