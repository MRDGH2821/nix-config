{
  config,
  pkgs,
  ...
}: {
  services.pgadmin = {
    emailServer = {
      address = config.networking.smtp.host;
      enable = true;
      passwordFile = config.sops.secrets.smtpPassword.path;
      port = config.networking.smtp.port;
      sender = config.networking.smtp.email;
      username = config.networking.smtp.email;
    };
    enable = true;
    initialEmail = config.networking.email;
    initialPasswordFile = config.sops.secrets.dummyPassword.path;
    openFirewall = true;
    # PostgreSQL 17.12+ exposes pg_attver as an internal column option.
    # pgAdmin 9.18 must not include it in generated SQL.
    package = pkgs.pgadmin4.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace web/pgadmin/browser/server_groups/servers/databases/schemas/tables/columns/utils.py \
            --replace-fail '        for spcoption in col_variables:' \
            $'        for spcoption in col_variables:\n            if spcoption.startswith("pg_attver="):\n                continue'
        '';
    });
    settings.SERVER_MODE = true;
  };
}
