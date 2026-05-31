{
  lib,
  config,
  pkgs,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;

  sops.templates.honcho = {
    content = ''
      DB_CONNECTION_URI=postgresql+psycopg://honcho@host.containers.internal:5432/honcho
      AUTH_USE_AUTH=true
      # PORT=8000
      CACHE_ENABLED=true
      CACHE_URL=redis://host.containers.internal:6381/0?suppress=true
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
    extraOptions = [
      # Resolve host.containers.internal to the gateway IP of the
      # honcho-memory_default podman network, so containers can
      # reach host services (PostgreSQL, Redis).
      "--add-host=host.containers.internal:host-gateway"
    ];
  };

  virtualisation.oci-containers.containers."honcho-memory-deriver" = {
    environmentFiles = [
      config.sops.secrets.honcho-memory.path
      config.sops.templates.honcho.path
    ];
    extraOptions = [
      "--add-host=host.containers.internal:host-gateway"
    ];
  };

  systemd.services."podman-honcho-memory-api" = {
    before = lib.mkAfter ["hermes-agent.service"];
    requires = lib.mkAfter [
      "postgresql.service"
      "redis-honcho.service"
    ];
    after = lib.mkAfter [
      "postgresql.service"
      "redis-honcho.service"
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
  };

  systemd.services."podman-honcho-memory-deriver" = {
    requires = lib.mkAfter [
      "podman-honcho-memory-api.service"
      "postgresql.service"
      "redis-honcho.service"
    ];
    after = lib.mkAfter [
      "podman-honcho-memory-api.service"
      "postgresql.service"
      "redis-honcho.service"
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
    };
  };

  systemd.services."podman-network-honcho-memory_default" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStop = "podman network rm -f honcho-memory_default";
    };
    script = ''
      podman network inspect honcho-memory_default || podman network create honcho-memory_default
    '';
    wantedBy = ["podman-honcho-memory-api.service"];
  };

  services.postgresql = {
    enable = true;
    # Listen on all TCP interfaces so containers on the dynamically-created
    # honcho-memory_default podman network can reach the host.
    enableTCPIP = true;
    extensions = [pkgs.postgresqlPackages.pgvector];
    # Trust connections from any network for the honcho user — the
    # honcho-memory_default podman network uses a dynamically allocated
    # subnet, so we can't pin a specific CIDR in advance.
    authentication = lib.mkOrder 400 ''
      host honcho honcho 0.0.0.0/0 trust
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
    # Listen on all interfaces so containers on the dynamically-created
    # honcho-memory_default podman network can reach the host.
    # Default is 127.0.0.1 ::1 only, which the network can't reach.
    bind = null;
    openFirewall = true;
    port = 6381;
  };
}
