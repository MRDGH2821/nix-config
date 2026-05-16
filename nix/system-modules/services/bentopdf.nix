{config, ...}: {
  services.bentopdf = {
    enable = true;
    domain = "pdf.${config.networking.baseDomain}";
  };
}
