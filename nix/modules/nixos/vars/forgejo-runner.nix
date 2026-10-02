{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.forgejo-runner;

  runtimeUnit =
    if cfg.containerRuntime == "podman"
    then "podman.socket"
    else "docker.service";

  runtimeGroup =
    if cfg.containerRuntime == "podman"
    then "podman"
    else "docker";

  yamlFormat = pkgs.formats.yaml {};

  connectionSettings =
    lib.mapAttrs (name: conn: {
      inherit (conn) url uuid labels;
      token_url = "file:/var/lib/forgejo-runner/token-${name}";
    })
    cfg.connections;

  mergedSettings = lib.recursiveUpdate cfg.settings {
    server.connections = connectionSettings;
  };

  configFile = yamlFormat.generate "forgejo-runner-config.yaml" mergedSettings;

  normalizeTokensScript = pkgs.writeShellScript "forgejo-runner-normalize-tokens" ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: _: ''
        src="$CREDENTIALS_DIRECTORY/token-${name}"
        dst="/var/lib/forgejo-runner/token-${name}"

        if grep -q '^TOKEN=' "$src"; then
          sed -n 's/^TOKEN=//p' "$src" | head -n1 | tr -d '\r\n' > "$dst"
        else
          tr -d '\r\n' < "$src" > "$dst"
        fi

        chmod 0600 "$dst"
      '')
      cfg.connections
    )}
  '';
in {
  config = lib.mkIf cfg.enable {
    assertions =
      [
        {
          assertion =
            if cfg.containerRuntime == "podman"
            then config.virtualisation.podman.enable
            else config.virtualisation.docker.enable;
          message = "services.forgejo-runner requires the ${cfg.containerRuntime} container runtime to be enabled.";
        }
      ]
      ++ lib.mapAttrsToList (name: _: {
        assertion = builtins.match "[A-Za-z0-9_-]+" name != null;
        message = "Forgejo runner connection name '${name}' must use only letters, numbers, underscores, or hyphens.";
      })
      cfg.connections;
    systemd.services.forgejo-runner = {
      after = [
        "network-online.target"
        runtimeUnit
      ];
      description = "Forgejo Actions Runner";
      environment =
        {
          HOME = "/var/lib/forgejo-runner";
        }
        // lib.optionalAttrs (cfg.containerRuntime == "podman") {
          DOCKER_HOST = "unix:///run/podman/podman.sock";
        };
      path = [pkgs.gitMinimal];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${lib.getExe cfg.package} daemon --config ${configFile}";
        ExecStartPre = normalizeTokensScript;
        LoadCredential = lib.mapAttrsToList (name: conn: "token-${name}:${conn.tokenFile}") cfg.connections;
        Restart = "on-failure";
        RestartSec = 2;
        StateDirectory = "forgejo-runner";
        StateDirectoryMode = "0700";
        SupplementaryGroups = [runtimeGroup];
        User = "forgejo-runner";
        WorkingDirectory = "/var/lib/forgejo-runner";
      };
      wantedBy = ["multi-user.target"];
      wants = [
        "network-online.target"
        runtimeUnit
      ];
    };
  };
  # nixpkgs 26.11 ships its own services.forgejo-runner module (previously
  # only services.gitea-actions-runner existed). This file is a full custom
  # reimplementation of the option tree + systemd unit, so disable upstream
  # to avoid "option services.forgejo-runner.package is already declared".
  disabledModules = ["services/continuous-integration/forgejo-runner.nix"];
  options.services.forgejo-runner = {
    connections = lib.mkOption {
      default = {};
      description = ''
        Forgejo instances this runner polls for jobs. Each attribute name
        becomes a key under `server.connections` in the generated
        config.yaml (see `forgejo-runner generate-config`).
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            labels = lib.mkOption {
              description = "Labels and execution environments advertised for this connection.";
              example = ["ubuntu-latest:docker://node:22-bookworm"];
              type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
            };
            tokenFile = lib.mkOption {
              description = ''
                Path to a runtime-only file (e.g. a sops-nix secret path)
                containing either the runner token directly or dotenv
                content with a TOKEN=... line. Loaded via systemd's
                LoadCredential= and normalized at runtime, never copied
                into the Nix store.
              '';
              example = "/run/secrets/forgejo-runner-token";
              type = lib.types.nonEmptyStr;
            };
            url = lib.mkOption {
              description = "URL of the Forgejo instance.";
              example = "https://git.example.com";
              type = lib.types.nonEmptyStr;
            };
            uuid = lib.mkOption {
              description = ''
                Runner UUID issued when the runner was registered in Forgejo.
                This is a public identifier, not a secret:
                https://forgejo.org/docs/latest/admin/actions/registration/
              '';
              example = "c9e50be9-a7c3-4aee-ba35-624c4ff8c519";
              type = lib.types.strMatching "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}";
            };
          };
        }
      );
    };
    containerRuntime = lib.mkOption {
      default = "podman";
      description = "OCI container runtime used to execute job containers.";
      type = lib.types.enum [
        "docker"
        "podman"
      ];
    };
    enable = lib.mkEnableOption "the Forgejo Actions runner daemon";
    package = lib.mkPackageOption pkgs "forgejo-runner" {};
    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = {};
      description = ''
        Extra forgejo-runner settings (log, runner, cache, host, container
        sections) merged into the generated config.yaml. See
        `forgejo-runner generate-config` for the full schema.
        The `server.connections.<name>` entries produced from
        `services.forgejo-runner.connections` take precedence over any
        matching keys set here (via `lib.recursiveUpdate`) -- do not set
        `settings.server.connections` directly.
      '';
    };
  };
}
