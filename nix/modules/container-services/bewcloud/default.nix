{
  config,
  lib,
  self,
  ...
}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
  bewcloud_path = "${config.persistent_storage}/bewcloud";
  data-files = "${bewcloud_path}/data-files";
  port = toString 8000;
in {
  imports = autoImportLib.autoImportModules ./.;

  # Create necessary directories for bewcloud container
  systemd.tmpfiles.rules = [
    "d ${bewcloud_path} 0755 root root -"
    "d ${data-files} 0755 root root -"
    "d ${data-files}/.Trash 0755 root root -"
    "d ${data-files}/Photos 0755 root root -"
    "d ${data-files}/Notes 0755 root root -"
  ];

  sops.templates.bewcloud.content = ''
    SMTP_PASSWORD=${config.sops.placeholder.smtpPassword}
  '';

  virtualisation.oci-containers.containers."bewcloud-website" = {
    volumes = lib.mkAfter [
      "${self.outPath}/nix/modules/container-services/bewcloud/bewcloud.env.config.ts:/app/bewcloud.config.ts:rw"
    ];
    environmentFiles = [
      config.sops.secrets.bewcloud.path
      config.sops.templates.bewcloud.path
    ];
    environment = {
      POSTGRESQL_HOST = "127.0.0.1";
      POSTGRESQL_USER = "bewcloud";
      POSTGRESQL_DBNAME = "bewcloud";
      POSTGRESQL_PORT = toString 5432;
      PORT = port;
      SMTP_USERNAME = config.networking.smtp.email;

      # Auth Configuration
      BEWCLOUD_AUTH_BASE_URL = "http://cloud.${config.networking.baseDomain}";
      BEWCLOUD_AUTH_ALLOW_SIGNUPS = toString false;
      BEWCLOUD_AUTH_ENABLE_EMAIL_VERIFICATION = toString false;
      BEWCLOUD_AUTH_ENABLE_FOREVER_SIGNUP = toString true;
      BEWCLOUD_AUTH_ENABLE_MULTI_FACTOR = toString false;

      # Comma-separated list of allowed cookie domains
      BEWCLOUD_AUTH_ALLOWED_COOKIE_DOMAINS = "cloud.${config.networking.baseDomain},*.${config.networking.baseDomain},localhost:${port}";

      # Set to true to skip cookie domain security checks (not recommended)
      BEWCLOUD_AUTH_SKIP_COOKIE_DOMAIN_SECURITY = toString false;

      # Single Sign-On Configuration
      BEWCLOUD_AUTH_ENABLE_SINGLE_SIGN_ON = toString true;
      BEWCLOUD_AUTH_SINGLE_SIGN_ON_URL = "https://authentik.${config.networking.baseDomain}/application/o/bewcloud/";
      BEWCLOUD_AUTH_SINGLE_SIGN_ON_EMAIL_ATTRIBUTE = "email";

      # Comma-separated list of scopes
      BEWCLOUD_AUTH_SINGLE_SIGN_ON_SCOPES = "openid,email";
      # Files Configuration
      BEWCLOUD_FILES_ROOT_PATH = "data-files";
      BEWCLOUD_FILES_ALLOW_PUBLIC_SHARING = toString false;
      # Core Configuration
      # Comma-separated list of enabled apps (dashboard and files cannot be disabled)
      BEWCLOUD_CORE_ENABLED_APPS = "news,notes,photos,expenses,contacts,calendar";
      # Visuals Configuration
      # BEWCLOUD_VISUALS_TITLE=
      # BEWCLOUD_VISUALS_DESCRIPTION=
      # BEWCLOUD_VISUALS_HELP_EMAIL=help@bewcloud.com

      # Email/SMTP Configuration
      BEWCLOUD_EMAIL_FROM = config.networking.smtp.email;
      BEWCLOUD_EMAIL_HOST = config.networking.smtp.host;
      BEWCLOUD_EMAIL_PORT = toString config.networking.smtp.port;
      # Contacts Configuration
      BEWCLOUD_CONTACTS_ENABLE_CARDDAV_SERVER = toString true;
      BEWCLOUD_CONTACTS_CARDDAV_URL = "http://127.0.0.1:5232";
      # Calendar Configuration
      BEWCLOUD_CALENDAR_ENABLE_CALDAV_SERVER = toString true;
      BEWCLOUD_CALENDAR_CALDAV_URL = "http://127.0.0.1:5232";
    };
  };

  services.postgresql = {
    ensureDatabases = ["bewcloud"];
    ensureUsers = [
      {
        name = "bewcloud";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
}
