{config, ...}: {
  services.pgadmin = {
    emailServer = {
      address = config.networking.smtp.host;
      enable = true;
      passwordFile = config.sops.secrets.smtpPassword.path;
      port = config.networking.smtp.port;
      sender = config.networking.smtp.email;
      username = config.networking.smtp.email;
    };
    enable = true;
    initialEmail = config.networking.email;
    initialPasswordFile = config.sops.secrets.dummyPassword.path;
    openFirewall = true;
    settings.SERVER_MODE = true;
  };
}
