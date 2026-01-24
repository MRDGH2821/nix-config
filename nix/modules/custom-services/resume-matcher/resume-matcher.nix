{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.resume-matcher;

  envList = env: lib.mapAttrsToList (name: value: "${name}=${value}") env;
in
{
  options.services.resume-matcher = {
    enable = lib.mkEnableOption "Resume Matcher (FastAPI + Next.js)";

    user = lib.mkOption {
      type = lib.types.str;
      default = "resume-matcher";
      description = "User that runs Resume Matcher services.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "resume-matcher";
      description = "Group that runs Resume Matcher services.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/resume-matcher";
      description = "Location to clone and run the Resume Matcher repository.";
    };

    repositoryUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/srbhr/Resume-Matcher.git";
      description = "Git repository to clone for Resume Matcher.";
    };

    rev = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch, tag, or commit to check out.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open firewall ports for the backend and frontend.";
    };

    backend = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Backend listen address.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8000;
        description = "Backend listen port.";
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional EnvironmentFile for backend secrets (e.g., LLM_API_KEY).";
      };

      extraEnv = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Additional backend environment variables.";
      };
    };

    frontend = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Frontend listen address.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Frontend listen port.";
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional EnvironmentFile for frontend settings.";
      };

      extraEnv = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Additional frontend environment variables.";
      };

      buildOnSetup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run npm run build during setup to produce a production build.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "Resume Matcher service user";
    };

    environment.systemPackages = with pkgs; [
      git
      uv
      nodejs_22
      python313
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.resume-matcher-setup = {
      description = "Prepare Resume Matcher checkout and dependencies";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
      };
      path = with pkgs; [
        git
        uv
        nodejs_22
        python313
        coreutils
        gnugrep
        gnused
        findutils
      ];
      script = ''
        set -euo pipefail

        # Initialize or update repository
        if [ ! -d "${cfg.dataDir}/.git" ]; then
          # If directory doesn't exist, create it and clone
          if [ ! -d "${cfg.dataDir}" ]; then
            git clone ${cfg.repositoryUrl} "${cfg.dataDir}"
          else
            # Directory exists but no .git - init and add remote
            cd "${cfg.dataDir}"
            git init
            git remote add origin ${cfg.repositoryUrl}
            git fetch origin
          fi
        else
          # Repository exists, just update it
          cd "${cfg.dataDir}"
        fi

        cd "${cfg.dataDir}"
        git fetch origin
        git checkout ${cfg.rev}
        git reset --hard "origin/${cfg.rev}"
        git submodule update --init --recursive

        cd apps/backend
        if [ ! -f .env ] && [ -f .env.example ]; then
        	cp .env.example .env
        fi
        uv sync

        cd ../frontend
        if [ ! -f .env.local ] && [ -f .env.sample ]; then
        	cp .env.sample .env.local
        fi
        npm install --no-progress
        ${lib.optionalString cfg.frontend.buildOnSetup ''
          NODE_ENV=production npm run build
        ''}
      '';
    };

    systemd.services.resume-matcher-backend = {
      description = "Resume Matcher backend (FastAPI)";
      after = [
        "resume-matcher-setup.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      requires = [ "resume-matcher-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        uv
        python313
      ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.dataDir}/apps/backend";
        Restart = "on-failure";
        RestartSec = 5;
        EnvironmentFiles = lib.optional (cfg.backend.environmentFile != null) cfg.backend.environmentFile;
        ExecStart = ''
          ${pkgs.uv}/bin/uv run uvicorn app.main:app \
          	--host ${cfg.backend.host} \
          	--port ${toString cfg.backend.port}
        '';
        Environment = envList (
          {
            HOST = cfg.backend.host;
            PORT = toString cfg.backend.port;
            FRONTEND_BASE_URL = "http://${cfg.frontend.host}:${toString cfg.frontend.port}";
            CORS_ORIGINS = "[\"http://${cfg.frontend.host}:${toString cfg.frontend.port}\", \"http://127.0.0.1:${toString cfg.frontend.port}\"]";
          }
          // cfg.backend.extraEnv
        );
      };
    };

    systemd.services.resume-matcher-frontend = {
      description = "Resume Matcher frontend (Next.js)";
      after = [
        "resume-matcher-backend.service"
        "resume-matcher-setup.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      requires = [ "resume-matcher-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.nodejs_22 ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.dataDir}/apps/frontend";
        Restart = "on-failure";
        RestartSec = 5;
        EnvironmentFiles = lib.optional (cfg.frontend.environmentFile != null) cfg.frontend.environmentFile;
        ExecStart = ''
          ${pkgs.nodejs_22}/bin/npm run start -- \
          	--hostname ${cfg.frontend.host} \
          	--port ${toString cfg.frontend.port}
        '';
        Environment = envList (
          {
            PORT = toString cfg.frontend.port;
            HOST = cfg.frontend.host;
            NODE_ENV = "production";
            BACKEND_URL = "http://${cfg.backend.host}:${toString cfg.backend.port}";
            NEXT_PUBLIC_BACKEND_URL = "http://${cfg.backend.host}:${toString cfg.backend.port}";
          }
          // cfg.frontend.extraEnv
        );
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.frontend.port
      cfg.backend.port
    ];
  };
}
