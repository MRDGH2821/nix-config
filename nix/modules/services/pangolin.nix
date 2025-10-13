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
      domains = {
        domain1 = {
          cert_resolver = "letsencrypt";
          prefer_wildcard_cert = true;
        };
      };
      smtp_host = "smtp.gmail.com";
      smtp_port = 587;
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = true;
      };
    };
    letsEncryptEmail = "letsencrypt@example.com";
    baseDomain = "pangolin.example.com";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
