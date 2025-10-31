{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];
  boot.kernelModules = ["wireguard"];

  sops.templates.pangolin.content = ''
    ${config.sops.placeholder.pangolin}

    EMAIL_SMTP_PASS=${config.sops.placeholder.smtpPassword}
  '';

  services.pangolin = {
    enable = true;
    openFirewall = true;
    settings = {
      app = {
        save_logs = true;
      };
      email = {
        smtp_host = config.networking.smtp.host;
        smtp_port = config.networking.smtp.port;
        smtp_user = config.networking.smtp.email;
      };
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = true;
      };
      domains = {
        domain1 = {
          cert_resolver = config.networking.dnsProvider;
          prefer_wildcard_cert = true;
        };
      };
    };
    letsEncryptEmail = config.networking.email;
    baseDomain = config.networking.baseDomain;
    environmentFile = config.sops.templates.pangolin.path;
    dnsProvider = config.networking.dnsProvider;
  };

  services.traefik = {
    environmentFiles = [
      config.sops.templates.acme.path
    ];
  };

  users.users.traefik = {
    extraGroups = ["docker"];
  };
}
