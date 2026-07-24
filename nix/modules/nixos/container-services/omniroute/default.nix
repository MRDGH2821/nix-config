{
  config,
  mylib,
  ...
}: {
  imports = mylib.autoImportModules ./.;
  services.redis.servers.omniroute = {
    bind = null;
    enable = true;
    openFirewall = true;
    port = 6382;
  };
  virtualisation.oci-containers.containers."omniroute-web" = {
    environment = {
      ALLOW_API_KEY_REVEAL = "false";
      API_PORT = "20129";
      AUTH_COOKIE_SECURE = "true";
      CONTAINER_HOST = "podman";
      CORS_ORIGIN = "https://omniroute.${config.networking.baseDomain}";
      DASHBOARD_PORT = "20128";
      # API_HOST = "0.0.0.0";
      # HOSTNAME = "0.0.0.0";
      DATA_DIR = "/app/data";
      INPUT_SANITIZER_ENABLED = "true";
      INPUT_SANITIZER_MODE = "block";
      MAX_BODY_SIZE_BYTES = "5242880"; # 5 MB limit
      NEXT_PUBLIC_BASE_URL = "https://omniroute.${config.networking.baseDomain}";
      NODE_ENV = "production";
      PII_REDACTION_ENABLED = "true";
      PII_RESPONSE_SANITIZATION = "true";
      PORT = "20128";
      REDIS_PORT = "6382";
      REDIS_URL = "redis://localhost:6382";
      REQUIRE_API_KEY = "true";
    };
    environmentFiles = [
      config.sops.secrets.omniroute.path
    ];
  };
}
