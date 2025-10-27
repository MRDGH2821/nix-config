{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];
  boot.kernelModules = ["wireguard"];
  services.pangolin = {
    enable = true;
    openFirewall = true;
    settings = {
      app = {
        save_logs = true;
      };
      smtp_host = config.networking.smtp.host;
      smtp_port = config.networking.smtp.port;
      smtp_user = config.networking.smtp.email;
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
    environmentFile = config.sops.secrets.pangolin.path;
    dnsProvider = config.networking.dnsProvider;
  };

  services.traefik = {
    environmentFiles = [
      config.sops.secrets.traefik.path
      config.sops.secrets.acme.path
    ];
  };
}
