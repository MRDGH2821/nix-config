{config, ...}: {
  services.bentopdf = {
    enable = true;
    domain = "pdf.${config.networking.baseDomain}";
    nginx.enable = true;
  };
  services.nginx.virtualHosts."${config.services.bentopdf.domain}" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 8090;
      }
    ];
  };
}
