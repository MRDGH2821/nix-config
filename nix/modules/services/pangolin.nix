{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];
  boot.kernelModules = ["wireguard"];
  sops.templates.pangolin = {
    smtpEmail = "${config.sops.placeholder.smtpEmail}";
    letsEncryptEmail = "${config.sops.placeholder.letsEncryptEmail}";
    baseDomain = "${config.sops.placeholder.baseDomain}";
  };

  services.pangolin = {
    enable = true;
    openFirewall = true;
    settings = {
      app = {
        save_logs = true;
      };
      domains = {
        domain1 = {
          cert_resolver = "letsencrypt";
          prefer_wildcard_cert = true;
        };
      };
      smtp_host = "smtp.gmail.com";
      smtp_port = 587;
      smtp_user = config.sops.templates.pangolin.smtpEmail;
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = true;
      };
    };
    letsEncryptEmail = config.sops.templates.pangolin.letsEncryptEmail;
    baseDomain = config.sops.templates.pangolin.baseDomain;
    environmentFile = config.sops.secrets.pangolin.path;
    dnsProvider = "duckdns";
  };

  services.traefik = {
    environmentFiles = [
      config.sops.secrets.traefik.path
      config.sops.secrets.acme.path
    ];
  };
}
