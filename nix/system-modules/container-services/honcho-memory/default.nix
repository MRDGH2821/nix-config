{
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;
  virtualisation.oci-containers.containers."honcho-memory-api" = {
    environmentFiles = [config.sops.secrets.honcho-memory.path];
    environment = {
      DB_CONNECTION_URI = "postgresql+psycopg://postgres:postgres@localhost:5432/postgres";
      AUTH_USE_AUTH = true;
      PORT = "3100";
      CACHE_ENABLED = true;
      CACHE_URL = "redis://localhost:6379/0?suppress=true";
      VECTOR_STORE_TYPE = "pgvector";
      LOG_LEVEL = "INFO";
      # Migration flag: set to true when migration from pgvector is complete
      VECTOR_STORE_MIGRATED = false;
    };
  };

  systemd.services."podman-honcho-memory-api" = {
    before = lib.mkAfter ["hermes-agent.service"];
    requires = lib.mkAfter [
      "postgresql.service"
      "redis-honcho.service"
    ];
  };

  systemd.services."podman-honcho-memory-deriver" = {
    after = lib.mkAfter ["podman-honcho-memory-api.service"];
    requires = lib.mkAfter [
      "podman-honcho-memory-api.service"
      "postgresql.service"
      "redis-honcho.service"
    ];
  };

  services.postgresql = {
    enable = true;
    extensions = ["pgvector"];
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
    openFirewall = true;
    port = 6381;
  };
}
