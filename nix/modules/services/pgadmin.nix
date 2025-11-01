{config, ...}: {
  services.pgadmin = {
    enable = true;
    openFirewall = true;
    settings = {
      SERVER_MODE = true;
      AUTHENTICATION_SOURCES = ["oauth2" "internal"];
      OAUTH2_AUTO_CREATE_USER = true;
    };
    initialEmail = config.networking.email;
    initialPasswordFile = config.sops.secrets.dummyPassword.path;
    emailServer = {
      enable = true;
      address = config.networking.smtp.host;
      port = config.networking.smtp.port;
      username = config.networking.smtp.email;
      passwordFile = config.sops.secrets.smtpPassword.path;
      sender = config.networking.smtp.email;
    };
  };
  environment.etc."pgadmin/config_local.py" = {
    source = config.sops.secrets.pgadmin.path;
    mode = "0640";
    owner = "pgadmin";
    group = "pgadmin";
  };
}
