{config, ...}: {
  sops.templates.acme.content = ''
    ${config.sops.placeholder.acme}

    LEGO_EMAIL=${config.sops.placeholder.letsEncryptEmail}
  '';
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = config.networking.email;
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.sops.templates.acme.path;
      group = config.services.caddy.group;
    };
    certs."${config.networking.baseDomain}" = {
      domain = "${config.networking.baseDomain}";
      extraDomainNames = ["*.${config.networking.baseDomain}"];
      dnsProvider = config.networking.dnsProvider;
    };
  };
}
