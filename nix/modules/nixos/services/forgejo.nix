{config, ...}: {
  services.forgejo = {
    database = {
      createDatabase = true;
      host = "localhost";
      type = "postgres";
    };
    dump = {
      backupDir = "${config.persistent_storage}/forgejo-dumps";
      enable = true;
      type = "tar.xz";
    };
    enable = true;
    lfs.enable = true;
    secrets.mailer.PASSWD = config.sops.secrets.smtpPassword.path;
    settings = {
      log.LEVEL = "Trace";
      mailer = {
        ENABLED = true;
        FROM = config.networking.smtp.email;
        PROTOCOL = "smtp+starttls";
        SMTP_ADDR = config.networking.smtp.host;
        SMTP_PORT = config.networking.smtp.port;
        USER = config.networking.smtp.email;
      };
      oauth2_client = {
        ACCOUNT_LINKING = "login";
        ENABLE_AUTO_REGISTRATION = true;
        OPENID_CONNECT_SCOPES = "profile email openid";
        REGISTER_EMAIL_CONFIRM = true;
      };
      openid = {
        ENABLE_OPENID_SIGNIN = true;
        ENABLE_OPENID_SIGNUP = true;
      };
      server = {
        DISABLE_SSH = true;
        DOMAIN = config.networking.baseDomain;
        HTTP_PORT = 4000;
        ROOT_URL = "https://git.${config.networking.baseDomain}";
      };
      service = {
        ENABLE_NOTIFY_MAIL = true;
        REGISTER_EMAIL_CONFIRM = true;
      };
    };
  };
}
