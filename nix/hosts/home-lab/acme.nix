{config, ...}: {
  security.acme.defaults.environmentFile = config.sops.secrets.acme.path;
}
