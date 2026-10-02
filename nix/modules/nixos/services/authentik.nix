{config, ...}: {
  services.authentik = {
    createDatabase = true;
    enable = true;
    environmentFile = config.sops.secrets.authentik.path;
    nginx.enable = false;
    settings = {
      avatars = "initials";
      disable_startup_analytics = true;
      email = {
        from = config.networking.smtp.email;
        host = config.networking.smtp.host;
        port = config.networking.smtp.port;
        use_tls = true;
        username = config.networking.smtp.email;
      };
    };
  };
}
