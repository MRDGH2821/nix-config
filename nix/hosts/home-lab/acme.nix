{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.networking.email;
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.acme.path;
      # group = config.services.caddy.group;
    };
    certs."${config.networking.baseDomain}" = {
      domain = "${config.networking.baseDomain}";
      extraDomainNames = ["*.${config.networking.baseDomain}"];
      dnsProvider = config.networking.dnsProvider;
    };
  };
}
