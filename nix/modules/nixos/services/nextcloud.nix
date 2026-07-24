{
  config,
  pkgs,
  ...
}: {
  services = {
    nextcloud = {
      caching.redis = true;
      config = {
        adminpassFile = config.sops.secrets.dummyPassword.path;
        adminuser = "mrdgh2821";
        dbtype = "pgsql";
      };
      configureRedis = true;
      database.createLocally = true;
      enable = true;
      hostName = "nextcloud";
      package = pkgs.nextcloud33;
      settings = {
        mail_domain = config.networking.smtp.email;
        mail_smtpauth = true;
        mail_smtphost = config.networking.smtp.host;
        mail_smtpname = config.networking.smtp.username;
        mail_smtpport = config.networking.smtp.port;
        trusted_domains = ["*.${config.networking.baseDomain}"];
        trusted_proxies = [
          "127.0.0.1"
          "192.168.1.150"
        ];
      };
    };
    nginx.virtualHosts."${config.services.nextcloud.hostName}".listen = [
      {
        addr = "127.0.0.1";
        port = 9200;
      }
    ];
  };
}
