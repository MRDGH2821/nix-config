{config, ...}: {
  services.ocis = {
    enable = true;
    environmentFile = config.sops.secrets.ocis.path;
  };
}
