{config, ...}: let
  dmn = config.vars.baseDomain;
  certloc = "/var/lib/acme/${dmn}";
in {
  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    virtualHosts."${dmn}".extraConfig = ''
      respond "OK"
    '';

    virtualHosts."pdf.${dmn}".extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.stirling-pdf.environment.SERVER_PORT}

      tls ${certloc}/cert.pem ${certloc}/key.pem {
        protocols tls1.3
      }
    '';
  };
}
