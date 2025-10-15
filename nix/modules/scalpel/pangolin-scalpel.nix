{
  lib,
  config,
  prev,
  pkgs,
  ...
}: let
  preStart = "${prev.config.systemd.services.pangolin.preStart}";
  pangolin_cfgfile = builtins.head (builtins.match ".*cp -f ([^[:space:]]+).*" "${preStart}");
in {
  systemd.services.pangolin.preStart = lib.mkForce (
    builtins.replaceStrings ["${pangolin_cfgfile}"] ["${config.scalpel.trafos."config.yaml".destination} "] "${preStart}"
  );

  # Restart pangolin after scalpel transformations complete
  systemd.services.pangolin = {
    restartTriggers = [
      config.scalpel.trafos."config.yaml".destination
    ];
    # Ensure pangolin starts after the scalpel activation
    after = ["sysinit.target"];
  };

  # Delayed restart service to ensure config is properly loaded after boot
  systemd.services.pangolin-delayed-restart = {
    description = "Restart pangolin 10 seconds after boot to ensure config is loaded";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target" "pangolin.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart pangolin.service";
      RemainAfterExit = true;
    };
  };

  scalpel.trafos."config.yaml" = {
    source = pangolin_cfgfile;
    matchers."SMTP_EMAIL".secret = config.sops.secrets.smtpEmail.path;
    matchers."LETSENCRYPT_EMAIL".secret = config.sops.secrets.letsEncryptEmail.path;
    matchers."BASE_DOMAIN".secret = config.sops.secrets.baseDomain.path;
    owner = "pangolin";
    group = "fossorial";
    mode = "0440";
  };
}
