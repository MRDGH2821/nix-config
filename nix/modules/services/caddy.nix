{config, ...}: let
  dmn = config.networking.baseDomain;
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
      tls {
          dns duckdns {env.DUCKDNS_TOKEN}
          resolvers 192.168.1.1:53 1.1.1.1:53 8.8.8.8:53
      }
    '';

    virtualHosts."pdf.${dmn}".extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.stirling-pdf.environment.SERVER_PORT}
      tls {
          dns duckdns {env.DUCKDNS_TOKEN}
          resolvers 192.168.1.1:53 1.1.1.1:53 8.8.8.8:53
      }
    '';
  };
}
