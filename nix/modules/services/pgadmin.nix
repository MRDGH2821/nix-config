{config, ...}: {
  services.pgadmin = {
    enable = true;
    openFirewall = true;
    settings = {
      SERVER_MODE = true;
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
}
