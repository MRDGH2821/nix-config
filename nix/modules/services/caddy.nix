{config, ...}: let
  dmn = config.networking.baseDomain;
in {
  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    virtualHosts."${dmn}".extraConfig = ''
      respond "OK"

      tls {
          resolvers 192.168.1.1:53 1.1.1.1:53 8.8.8.8:53
      }
    '';

    virtualHosts."pdf.${dmn}".extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.stirling-pdf.environment.SERVER_PORT}
      tls {
          resolvers 192.168.1.1:53 1.1.1.1:53 8.8.8.8:53
      }
    '';
  };
}
