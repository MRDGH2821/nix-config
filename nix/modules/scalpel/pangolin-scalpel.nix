{
  lib,
  config,
  prev,
  ...
}: let
  # The upstream preStart does: cp -f ${cfgFile} ${cfg.dataDir}/config/config.yml
  # We'll add an additional step to copy the scalpel-transformed config
  originalPreStart = "${prev.config.systemd.services.pangolin.preStart}";
  scalpelConfigPath = config.scalpel.trafos."config.yml".destination;
in {
  # Override the preStart to add scalpel config copy AFTER the original copy
  systemd.services.pangolin.preStart = lib.mkForce ''
    ${originalPreStart}

    # Copy scalpel-transformed config over the nix store config
    # This must happen after the mkdir and original cp
    if [ -f ${scalpelConfigPath} ]; then
      echo "[scalpel] Copying transformed config from ${scalpelConfigPath}"
      cp -f ${scalpelConfigPath} ${prev.config.services.pangolin.dataDir}/config/config.yml
    else
      echo "[scalpel] WARNING: Scalpel config not found at ${scalpelConfigPath}"
    fi
  '';

  # Restart pangolin after scalpel transformations complete
  systemd.services.pangolin = {
    restartTriggers = [
      scalpelConfigPath
    ];
    # Ensure pangolin starts after the scalpel activation
    after = ["sysinit.target"];
  };

  # Scalpel transformation configuration
  scalpel.trafos."config.yml" = {
    source = "${prev.config.services.pangolin.dataDir}/config/config.yml";
    matchers."SMTP_EMAIL".secret = config.sops.secrets.smtpEmail.path;
    matchers."LETSENCRYPT_EMAIL".secret = config.sops.secrets.letsEncryptEmail.path;
    matchers."BASE_DOMAIN".secret = config.sops.secrets.baseDomain.path;
    owner = "pangolin";
    group = "fossorial";
    mode = "0440";
  };
}
