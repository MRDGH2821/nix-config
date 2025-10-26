{lib, ...}: {
  options.vars = {
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
  };
}
