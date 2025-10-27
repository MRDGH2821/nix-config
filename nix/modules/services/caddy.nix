{config, ...}: let
  dmn = config.networking.baseDomain;
  certloc = config.security.acme.certs."${dmn}".directory;
in {
  networking.firewall.allowedTCPPorts = [80 443];

  sops.templates."caddy.env".content = ''
    DUCKDNS_TOKEN="${config.sops.placeholder.duckDnsToken}";
  '';

  services.caddy = {
    enable = true;
    environmentFile = config.sops.templates."caddy.env".path;
    virtualHosts."${dmn}".extraConfig = ''
      respond "OK"
      tls ${certloc}/cert.pem ${certloc}/key.pem {
        protocols tls1.3
      }
    '';

    virtualHosts."pdf.${dmn}".extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.stirling-pdf.environment.SERVER_PORT}
      tls ${certloc}/cert.pem ${certloc}/key.pem {
        protocols tls1.3
      }
    '';
  };
}
