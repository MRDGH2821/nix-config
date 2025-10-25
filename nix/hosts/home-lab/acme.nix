{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.vars.email;
      # group = config.services.caddy.group;
    };
    certs."${config.vars.baseDomain}" = {
      # group = config.services.caddy.group;
      # domain = "${config.vars.baseDomain}";
      # extraDomainNames = ["*.${config.vars.baseDomain}"];
      # dnsProvider = config.vars.dnsProvider;
      # dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.acme.path;
    };
  };
}
