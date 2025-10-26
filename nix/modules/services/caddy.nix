{config, ...}: let
  dmn = config.vars.baseDomain;
in {
  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    virtualHosts."${dmn}".extraConfig = ''
      respond "OK"
    '';

    virtualHosts."pdf.${dmn}".extraConfig = ''
      reverse_proxy http://localhost:${toString config.services.stirling-pdf.environment.SERVER_PORT}

    '';
  };
}
