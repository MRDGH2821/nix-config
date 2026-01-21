{
  config,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "ocis_5-bin"
    ];
  services.ocis = {
    enable = true;
    environmentFile = config.sops.secrets.ocis.path;
  };
}
