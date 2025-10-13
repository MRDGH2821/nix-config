{
  lib,
  config,
  prev,
  ...
}: let
  preStart = "${prev.config.systemd.services.pangolin.preStart}";
  pangolin_cfgfile = builtins.head (builtins.match ".*cp -f ([^[:space:]]+).*" "${preStart}");
in {
  systemd.services.pangolin.preStart = lib.mkForce (
    builtins.replaceStrings ["${pangolin_cfgfile}"] ["${config.scalpel.trafos."config.yaml".destination} "] "${preStart}"
  );
  scalpel.trafos."config.yaml" = {
    source = pangolin_cfgfile;
    matchers."SMTP_USER".secret = config.sops.secrets.smtpEmail.path;
    matchers."LETSENCRYPT_EMAIL".secret = config.sops.secrets.letsEncryptEmail.path;
    matchers."BASE_DOMAIN".secret = config.sops.secrets.baseDomain.path;
    owner = "pangolin";
    group = "fossorial";
    mode = "0440";
  };
}
