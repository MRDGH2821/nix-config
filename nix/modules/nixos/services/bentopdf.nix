{config, ...}: {
  services = {
    bentopdf = {
      domain = "pdf.${config.networking.baseDomain}";
      enable = true;
      nginx.enable = true;
    };
    nginx.virtualHosts."${config.services.bentopdf.domain}".listen = [
      {
        addr = "127.0.0.1";
        port = 8090;
      }
    ];
  };
}
