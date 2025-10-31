{config, ...}: {
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts = {
      default = {
        user = config.networking.smtp.username;
        passwordeval = "cat ${config.sops.secrets.smtpPassword.path}";
        host = config.networking.smtp.host;
        port = config.networking.smtp.port;
        auth = "on";
        tls = "on";
        tls_starttls = "on";
        from = config.networking.smtp.email;
        logfile = "/var/log/msmtp.log";
        syslog = "on";
      };
    };
  };
}
