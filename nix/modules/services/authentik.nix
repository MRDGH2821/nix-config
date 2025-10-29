{config, ...}: {
  services.authentik = {
    enable = true;
    createDatabase = true;
    nginx.enable = false;
    environmentFile = config.sops.secrets.authentik.path;
    settings = {
      email = {
        host = config.networking.smtp.host;
        port = config.networking.smtp.port;
        username = config.networking.smtp.email;
        from = config.networking.smtp.email;
        use_tls = true;
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
}
