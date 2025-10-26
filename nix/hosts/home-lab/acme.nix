{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.vars.email;
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.acme.path;
      # group = config.services.caddy.group;
    };
    certs."${config.vars.baseDomain}" = {
      domain = "${config.vars.baseDomain}";
      extraDomainNames = ["*.${config.vars.baseDomain}"];
      dnsProvider = config.vars.dnsProvider;
    };
  };
}
