{lib, ...}: {
  options.networking = {
    baseDomain = lib.mkOption {
      default = "your-new-domain.com";
      description = "Base domain for services";
      type = lib.types.str;
    };
    dnsProvider = lib.mkOption {
      default = "your-provider";
      description = "DNS provider name for ACME/lego";
      type = lib.types.str;
    };
    email = lib.mkOption {
      default = "your-new-email@example.com";
      description = "Admin email address";
      type = lib.types.str;
    };
    smtp = lib.mkOption {
      type = lib.types.submodule {
        options = {
          email = lib.mkOption {
            default = "user@example.com";
            type = lib.types.str;
          };
          host = lib.mkOption {
            default = "smtp.example.com";
            type = lib.types.str;
          };
          port = lib.mkOption {
            default = 587;
            type = lib.types.port;
          };
          security = lib.mkOption {
            default = "starttls";
            description = "SMTP security mode";
            type = lib.types.enum [
              "starttls"
              "tls"
              "none"
            ];
          };
          username = lib.mkOption {
            default = "user";
            description = "SMTP username";
            type = lib.types.str;
          };
        };
      };
    };
  };
}
