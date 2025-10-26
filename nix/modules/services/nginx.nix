{config, ...}: let
  dmn = config.networking.baseDomain;
in {
  networking.firewall.allowedTCPPorts = [80 443];

  services.nginx = {
    enable = false;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    # enableHTTP2 = true;
    virtualHosts."${dmn}" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = false;
          extraConfig =
            "proxy_ssl_server_name on;"
            + "proxy_pass_header Authorization;";
        };
      };
    };
    virtualHosts."pdf.${dmn}" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.stirling-pdf.environment.SERVER_PORT}";
        };
      };
    };
  };
}
