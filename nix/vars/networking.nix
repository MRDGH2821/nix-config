{lib, ...}: {
  options.networking = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "your-new-domain.com"; # Change this
      description = "Base domain for services";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "your-new-email@example.com"; # Change this
      description = "Admin email address";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "your-provider";
      description = "DNS provider name, from https://go-acme.github.io/lego/dns/index.html";
    };

    smtp = lib.mkOption {
      type = lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "smtp.example.com";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 587;
          };
          email = lib.mkOption {
            type = lib.types.str;
            default = "user@example.com";
          };
          security = lib.mkOption {
            type = lib.types.enum [
              "starttls"
              "tls"
              "none"
            ];
            default = "starttls";
            description = "SMTP security mode: starttls, tls, or none";
          };
          username = lib.mkOption {
            type = lib.types.str;
            default = "user";
            description = "SMTP username from the email address";
          };
        };
      };
    };
  };
}
