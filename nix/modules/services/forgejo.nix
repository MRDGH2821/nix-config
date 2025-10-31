{config, ...}: {
  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      host = "localhost";
      createDatabase = true;
    };
    dump = {
      enable = true;
      backupDir = "${config.persistent_storage}/forgejo-dumps";
      type = "tar.xz";
    };
    lfs = {
      enable = true;
    };
    settings = {
      server = {
        DISABLE_SSH = true;
        HTTP_PORT = 4000;
        DOMAIN = config.networking.baseDomain;
        ROOT_URL = "https://git.${config.networking.baseDomain}";
      };
      openid = {
        ENABLE_OPENID_SIGNIN = true;
        ENABLE_OPENID_SIGNUP = true;
      };
      oauth2_client = {
        REGISTER_EMAIL_CONFIRM = true;
        OPENID_CONNECT_SCOPES = "profile email openid";
        ENABLE_AUTO_REGISTRATION = true;
        ACCOUNT_LINKING = "login";
      };
      service = {
        REGISTER_EMAIL_CONFIRM = true;
        ENABLE_NOTIFY_MAIL = true;
      };
      mailer = {
        ENABLED = true;
        PROTOCOL = "smtp+starttls";
        SMTP_ADDR = config.networking.smtp.host;
        SMTP_PORT = config.networking.smtp.port;
        USER = config.networking.smtp.email;
        FROM = config.networking.smtp.email;
      };
    };
    secrets = {
      mailer.PASSWD = config.sops.secrets.smtpPassword.path;
    };
  };
}
