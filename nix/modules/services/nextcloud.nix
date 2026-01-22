{config}: {
  services.nextcloud = {
    config = {
      dbtype = "pgsql";
    };
    caching = {
      redis = true;
    };
    configureRedis = true;
    database = {
      createLocally = true;
    };
    enable = true;
    url = "https://nextcloud.${config.networking.baseDomain}";
    settings = {
      trusted_proxies = ["127.0.0.1" "192.168.1.150" "${config.networking.baseDomain}"];
      trusted_domains = ["${config.networking.baseDomain}"];
      mail_domain = config.networking.smtp.email;
      mail_smtpauth = true;
      mail_smtphost = config.networking.smtp.host;
      mail_smtpname = config.networking.smtp.username;
      mail_smtpport = config.networking.smtp.port;
    };
  };
}
