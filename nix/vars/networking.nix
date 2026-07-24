{lib, ...}: {
  options.networking = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "your-new-domain.com";
      description = "Base domain for services";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "your-new-email@example.com";
      description = "Admin email address";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "your-provider";
      description = "DNS provider name for ACME/lego";
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
            description = "SMTP security mode";
          };
          username = lib.mkOption {
            type = lib.types.str;
            default = "user";
            description = "SMTP username";
          };
        };
      };
    };
  };
}
