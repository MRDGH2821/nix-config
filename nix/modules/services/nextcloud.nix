{
  config,
  pkgs,
  ...
}: {
  services.nextcloud = {
    config = {
      adminuser = "mrdgh2821";
      adminpassFile = config.sops.secrets.dummyPassword.path;
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
    hostName = "nextcloud";
    package = pkgs.nextcloud32;
    settings = {
      trusted_proxies = [
        "127.0.0.1"
        "192.168.1.150"
      ];
      trusted_domains = ["*.${config.networking.baseDomain}"];
      mail_domain = config.networking.smtp.email;
      mail_smtpauth = true;
      mail_smtphost = config.networking.smtp.host;
      mail_smtpname = config.networking.smtp.username;
      mail_smtpport = config.networking.smtp.port;
    };
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 9200;
      }
    ];
  };
}
