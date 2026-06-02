{
  pkgs,
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;

  sops.templates.honcho = {
    content = ''
      DB_CONNECTION_URI=postgresql+psycopg://honcho@localhost:5432/honcho
      AUTH_USE_AUTH=true
      # PORT=8000
      CACHE_ENABLED=true
      CACHE_URL=redis://localhost:6381/0?suppress=true
      VECTOR_STORE_TYPE=pgvector
      LOG_LEVEL=INFO
      # Migration flag: set to true when migration from pgvector is complete
      VECTOR_STORE_MIGRATED=false
    '';
  };

  virtualisation.oci-containers.containers."honcho-memory-api" = {
    environmentFiles = [
      config.sops.secrets.honcho-memory.path
      config.sops.templates.honcho.path
    ];
  };

  virtualisation.oci-containers.containers."honcho-memory-deriver" = {
    environmentFiles = [
      config.sops.secrets.honcho-memory.path
      config.sops.templates.honcho.path
    ];
  };

  virtualisation.oci-containers.containers."honcho-memory-migrate" = {
    environmentFiles = [
      config.sops.secrets.honcho-memory.path
      config.sops.templates.honcho.path
    ];
  };

  systemd.services."podman-honcho-memory-migrate" = {
    requires = [
      "postgresql.service"
    ];
    after = [
      "postgresql.service"
    ];
  };

  systemd.services."podman-honcho-memory-api" = {
    requires = [
      "postgresql.service"
      "redis-honcho.service"
      "podman-honcho-memory-migrate.service"
    ];
    after = [
      "postgresql.service"
      "redis-honcho.service"
      "podman-honcho-memory-migrate.service"
    ];

    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
  };

  systemd.services."podman-honcho-memory-deriver" = {
    requires = ["podman-honcho-memory-api.service"];
    after = ["podman-honcho-memory-api.service"];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
  };

  # might need to create the extension manually
  # systemd.services.postgresql.postStart = lib.mkAfter ''
  #   psql -d honcho -c "CREATE EXTENSION IF NOT EXISTS vector;"
  # '';

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    extensions = [pkgs.postgresqlPackages.pgvector];
    initialScript = pkgs.writeText "init-honcho.sql" ''
      CREATE EXTENSION IF NOT EXISTS vector;
    '';
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      host all all 0.0.0.0/0 scram-sha-256
      host all all ::/0 scram-sha-256
    '';
    ensureDatabases = ["honcho"];
    ensureUsers = [
      {
        name = "honcho";
        ensureDBOwnership = true;
      }
    ];
  };

  services.redis.servers.honcho = {
    enable = true;
    bind = null;
    openFirewall = true;
    port = 6381;
  };
}
