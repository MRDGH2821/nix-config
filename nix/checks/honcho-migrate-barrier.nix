{
  flake,
  lib ? pkgs.lib,
  pkgs,
  ...
}: let
  services = flake.nixosConfigurations.home-lab.config.systemd.services;
  migrate = services.podman-honcho-memory-migrate;
  api = services.podman-honcho-memory-api;
  deriver = services.podman-honcho-memory-deriver;
  inherit (migrate) script;
  migrateUnit = "podman-honcho-memory-migrate.service";
  waits = service: lib.elem migrateUnit service.after && lib.elem migrateUnit service.requires;
  # The OCI generator keeps this unit active once the runtime starts.
  # A completion barrier is a foreground command with no readiness socket.
  detached =
    lib.hasInfix "--sdnotify" script
    || lib.hasInfix "\n  -d \\\n" script
    || lib.hasInfix "--detach" script;
  problems =
    lib.optional (
      (migrate.serviceConfig.Type or null) != "oneshot"
    ) "migration unit is not a completion barrier"
    ++ lib.optional (
      (migrate.serviceConfig.RemainAfterExit or false) != true
    ) "migration unit does not stay active after success"
    ++ lib.optional (
      (migrate.serviceConfig.Restart or null) != "no"
    ) "migration unit restarts after failure"
    ++ lib.optional detached "migration command returns when the container starts"
    ++ lib.optional (!lib.hasInfix "exec podman run" script) "migration command is not a foreground podman run"
    ++ lib.optional (
      !lib.hasInfix "upgrade" script || !lib.hasInfix "head" script
    ) "migration command does not apply the schema head"
    ++ lib.optional (!waits api) "API does not wait for a successful migration"
    ++ lib.optional (!waits deriver) "deriver does not wait for a successful migration";
in
  if problems != []
  then throw "honcho migration barrier regression: ${lib.concatStringsSep "; " problems}"
  else
    pkgs.runCommand "honcho-migrate-barrier" {} ''
      touch "$out"
    ''
