{
  lib,
  config,
  prev,
  pkgs,
  ...
}: let
  preStart = "${prev.config.systemd.services.pangolin.preStart}";
  pangolin_cfgfile = builtins.head (builtins.match ".*cp -f ([^[:space:]]+).*" "${preStart}");

  # Create a scalpel script that will run before the service starts
  scalpelScript = pkgs.callPackage ../../packages/scalpel.nix {
    matchers = {
      "SMTP_EMAIL" = config.sops.secrets.smtpEmail.path;
      "LETSENCRYPT_EMAIL" = config.sops.secrets.letsEncryptEmail.path;
      "BASE_DOMAIN" = config.sops.secrets.baseDomain.path;
    };
    source = pangolin_cfgfile;
    destination = "/run/scalpel/config.yaml";
    user = "pangolin";
    group = "fossorial";
    mode = "0440";
  };
in {
  # Add scalpel transformation as ExecStartPre
  systemd.services.pangolin.serviceConfig.ExecStartPre = lib.mkBefore [
    "+${scalpelScript}"
  ];

  # Update preStart to use the scalpel-transformed file
  systemd.services.pangolin.preStart = lib.mkForce (
    builtins.replaceStrings ["${pangolin_cfgfile}"] ["/run/scalpel/config.yaml "] "${preStart}"
  );
}
