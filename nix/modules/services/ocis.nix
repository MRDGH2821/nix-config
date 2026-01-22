{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "ocis_5-bin"
    ];

  environment.systemPackages = with pkgs; [
    ocis_5-bin
  ];

  sops.templates.ocis = {
    content = ''
      ${config.sops.placeholder.ocis}

      SMTP_HOST=${config.networking.smtp.host}
      SMTP_PORT=${toString config.networking.smtp.port}
      SMTP_SENDER=${config.networking.smtp.email}
      SMTP_USERNAME=${config.networking.smtp.username}
      SMTP_PASSWORD=${config.sops.placeholder.smtpPassword}
      SMTP_AUTHENTICATION=${config.networking.smtp.security}
      EMAIL_SERVER=smtp://${config.networking.smtp.username}:${config.sops.placeholder.smtpPassword}@${config.networking.smtp.host}:${toString config.networking.smtp.port}
    '';
  };
  services.ocis = {
    enable = true;
    environmentFile = config.sops.templates.ocis.path;
  };
}
