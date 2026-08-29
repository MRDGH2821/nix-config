{
  config,
  pkgs,
  ...
}: {
  boot.kernelModules = ["wireguard"];
  environment.systemPackages = with pkgs; [fosrl-pangolin];
  services = {
    pangolin = {
      baseDomain = config.networking.baseDomain;
      dnsProvider = config.networking.dnsProvider;
      enable = true;
      environmentFile = config.sops.templates.pangolin.path;
      letsEncryptEmail = config.networking.email;
      openFirewall = true;
      settings = {
        app.save_logs = true;
        domains.domain1 = {
          cert_resolver = config.networking.dnsProvider;
          prefer_wildcard_cert = true;
        };
        email = {
          smtp_host = config.networking.smtp.host;
          smtp_port = config.networking.smtp.port;
          smtp_user = config.networking.smtp.email;
        };
        flags = {
          disable_signup_without_invite = true;
          disable_user_create_org = true;
          require_email_verification = false;
        };
      };
    };
    traefik.environmentFiles = [
      config.sops.templates.acme.path
    ];
  };
  sops.templates.pangolin.content = ''
    ${config.sops.placeholder.pangolin}

    EMAIL_SMTP_PASS=${config.sops.placeholder.smtpPassword}
  '';
  users.users.traefik.extraGroups = [
    "docker"
    "podman"
  ];
}
