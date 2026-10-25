{
  config,
  flake,
  lib,
  ...
}: let
  migrate = config.virtualisation.oci-containers.containers.honcho-memory-migrate;
  # The generated unit detaches and reports ready when the runtime starts.
  # This foreground command keeps the unit starting until the migration exits.
  migrateCommand = lib.concatStringsSep " \\\n  " (
    [
      "exec podman run"
      "--name=honcho-memory-migrate"
      "--log-driver=${lib.escapeShellArg migrate."log-driver"}"
      # antipatterns: ignore NL11 — Podman's runtime name-replacement flag, not substituteInPlace.
      "--replace"
      "--rm"
      "--pull ${lib.escapeShellArg migrate.pull}"
    ]
    ++ map lib.escapeShellArg migrate.extraOptions
    ++ map (file: "--env-file ${lib.escapeShellArg file}") migrate.environmentFiles
    ++ map (volume: "-v ${lib.escapeShellArg volume}") migrate.volumes
    ++ [(lib.escapeShellArg migrate.image)]
  );
in {
  imports = flake.lib.autoImportModules ./.;
  services = {
    postgresql = {
      enable = true;
      enableTCPIP = true;
      ensureDatabases = ["honcho"];
      ensureUsers = [
        {
          ensureDBOwnership = true;
          name = "honcho";
        }
      ];
      extensions = ps: [ps.pgvector];
    };
    redis.servers.honcho = {
      bind = null;
      enable = true;
      openFirewall = true;
      port = 6381;
    };
  };
  sops.templates.honcho.content = ''
    DB_CONNECTION_URI=postgresql+psycopg://honcho@/honcho?host=/run/postgresql
    AUTH_USE_AUTH=true
    # PORT=8000
    CACHE_ENABLED=true
    CACHE_URL=redis://localhost:6381/0?suppress=true
    VECTOR_STORE_TYPE=pgvector
    LOG_LEVEL=INFO
    # Migration flag: set to true when migration from pgvector is complete
    VECTOR_STORE_MIGRATED=false
  '';
  systemd.services = {
    "podman-honcho-memory-api" = {
      after = [
        "postgresql.service"
        "redis-honcho.service"
        "podman-honcho-memory-migrate.service"
      ];
      requires = [
        "postgresql.service"
        "redis-honcho.service"
        "podman-honcho-memory-migrate.service"
      ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        StartLimitBurst = 3;
        StartLimitIntervalSec = 60;
      };
    };
    "podman-honcho-memory-deriver" = {
      after = [
        "podman-honcho-memory-api.service"
        "podman-honcho-memory-migrate.service"
      ];
      requires = [
        "podman-honcho-memory-api.service"
        "podman-honcho-memory-migrate.service"
      ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
        StartLimitBurst = 3;
        StartLimitIntervalSec = 60;
      };
    };
    "podman-honcho-memory-migrate" = {
      after = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      postStop = lib.mkForce "true";
      preStop = lib.mkForce "true";
      requires = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      script = lib.mkForce migrateCommand;
      serviceConfig = {
        RemainAfterExit = true;
        Type = lib.mkForce "oneshot";
      };
    };
    postgresql-setup = {
      # Repeat database-local extension setup whenever PostgreSQL restarts.
      partOf = ["postgresql.service"];
      postStart = lib.mkAfter ''
        psql -U postgres -d honcho -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS vector;"
      '';
    };
  };
  virtualisation.oci-containers.containers = {
    "honcho-memory-api" = {
      environmentFiles = [
        config.sops.secrets.honcho-memory.path
        config.sops.templates.honcho.path
      ];
      volumes = [
        "/run/postgresql:/run/postgresql"
      ];
    };
    "honcho-memory-deriver" = {
      environmentFiles = [
        config.sops.secrets.honcho-memory.path
        config.sops.templates.honcho.path
      ];
      volumes = [
        "/run/postgresql:/run/postgresql"
      ];
    };
    "honcho-memory-migrate" = {
      environmentFiles = [
        config.sops.secrets.honcho-memory.path
        config.sops.templates.honcho.path
      ];
      volumes = [
        "/run/postgresql:/run/postgresql"
      ];
    };
  };
}
