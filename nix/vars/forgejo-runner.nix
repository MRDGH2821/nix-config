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
    lib.mapAttrs
    (name: conn: {
      inherit (conn) url uuid labels;
      token_url = "file:$CREDENTIALS_DIRECTORY/token-${name}";
    })
    cfg.connections;

  mergedSettings = lib.recursiveUpdate cfg.settings {
    server.connections = connectionSettings;
  };

  configFile = yamlFormat.generate "forgejo-runner-config.yaml" mergedSettings;
in {
  options.services.forgejo-runner = {
    enable = lib.mkEnableOption "the Forgejo Actions runner daemon";

    package = lib.mkPackageOption pkgs "forgejo-runner" {};

    containerRuntime = lib.mkOption {
      type = lib.types.enum [
        "docker"
        "podman"
      ];
      default = "podman";
      description = "OCI container runtime used to execute job containers.";
    };

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
            url = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "URL of the Forgejo instance.";
              example = "https://git.example.com";
            };

            uuid = lib.mkOption {
              type = lib.types.strMatching "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}";
              description = ''
                Runner UUID issued when the runner was registered in Forgejo.
                This is a public identifier, not a secret:
                https://forgejo.org/docs/latest/admin/actions/registration/
              '';
              example = "c9e50be9-a7c3-4aee-ba35-624c4ff8c519";
            };

            tokenFile = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = ''
                Path to a runtime-only file (e.g. a sops-nix secret path)
                containing just the runner token. Loaded via systemd's
                LoadCredential=, never copied into the Nix store.
              '';
              example = "/run/secrets/forgejo-runner-token";
            };

            labels = lib.mkOption {
              type = lib.types.nonEmptyListOf lib.types.nonEmptyStr;
              description = "Labels and execution environments advertised for this connection.";
              example = ["ubuntu-latest:docker://node:22-bookworm"];
            };
          };
        }
      );
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = {};
      description = ''
        Extra forgejo-runner settings (log, runner, cache, host, container
        sections) merged into the generated config.yaml. See
        `forgejo-runner generate-config` for the full schema.
        `server.connections` is always overridden by
        `services.forgejo-runner.connections`.
      '';
    };
  };

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
      ++ lib.mapAttrsToList
      (name: _: {
        assertion = builtins.match "[A-Za-z0-9_-]+" name != null;
        message = "Forgejo runner connection name '${name}' must use only letters, numbers, underscores, or hyphens.";
      })
      cfg.connections;

    systemd.services.forgejo-runner = {
      description = "Forgejo Actions Runner";
      wantedBy = ["multi-user.target"];
      wants = [
        "network-online.target"
        runtimeUnit
      ];
      after = [
        "network-online.target"
        runtimeUnit
      ];

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
        User = "forgejo-runner";
        SupplementaryGroups = [runtimeGroup];
        StateDirectory = "forgejo-runner";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/forgejo-runner";
        LoadCredential = lib.mapAttrsToList (name: conn: "token-${name}:${conn.tokenFile}") cfg.connections;
        ExecStart = "${lib.getExe cfg.package} daemon --config ${configFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
