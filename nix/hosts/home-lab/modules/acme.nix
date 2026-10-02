{config, ...}: {
  security.acme = {
    acceptTerms = true;
    certs."${config.networking.baseDomain}" = {
      dnsProvider = config.networking.dnsProvider;
      domain = "${config.networking.baseDomain}";
      extraDomainNames = ["*.${config.networking.baseDomain}"];
    };
    defaults = {
      dnsPropagationCheck = true;
      dnsResolver = "1.1.1.1:53";
      email = config.networking.email;
      environmentFile = config.sops.templates.acme.path;
      group = config.services.traefik.group;
    };
  };
  sops.templates.acme.content = ''
    ${config.sops.placeholder.acme}

    LEGO_EMAIL=${config.sops.placeholder.letsEncryptEmail}
  '';
}
