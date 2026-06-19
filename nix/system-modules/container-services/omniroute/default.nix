{
  pkgs,
  lib,
  config,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;

  virtualisation.oci-containers.containers."omniroute-web" = {
    environmentFiles = [
      config.sops.secrets.omniroute.path
    ];
    environment = {
      REDIS_URL = "redis://localhost:6382";
      REDIS_PORT = "6382";
      NEXT_PUBLIC_BASE_URL = "https://omniroute.${config.networking.baseDomain}";
      AUTH_COOKIE_SECURE = "true";
      REQUIRE_API_KEY = "true";
      ALLOW_API_KEY_REVEAL = "false";
      CORS_ORIGIN = "https://omniroute.${config.networking.baseDomain}";
      MAX_BODY_SIZE_BYTES = "5242880"; # 5 MB limit
      INPUT_SANITIZER_ENABLED = "true";
      INPUT_SANITIZER_MODE = "block";
      PII_REDACTION_ENABLED = "true";
      PII_RESPONSE_SANITIZATION = "true";
      CONTAINER_HOST = "podman";
      NODE_ENV = "production";
      PORT = "20128";
      DASHBOARD_PORT = "20128";
      API_PORT = "20129";
      # API_HOST = "0.0.0.0";
      # HOSTNAME = "0.0.0.0";
      DATA_DIR = "/app/data";
    };
    volumes = lib.mkAfter [
      "${pkgs.tailscale}:${pkgs.tailscale}:ro"
      "${pkgs.tailscale}/bin/tailscale:/usr/local/bin/tailscale:ro"
      "${pkgs.tailscale}/bin/tailscaled:/usr/local/bin/tailscaled:ro"
    ];
  };

  services.redis.servers.omniroute = {
    enable = true;
    bind = null;
    openFirewall = true;
    port = 6382;
  };
}
