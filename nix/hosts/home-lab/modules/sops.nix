{
  lib,
  ...
}: {
  # Secrets are age-encrypted for:
  #   - admin age18mhd… (local sops editing)
  #   - host SSH ed25519 → age1t6v85… (activation on home-lab)
  #
  # Use host ed25519 via age.sshKeyPaths so sops-install-secrets can import it.
  # Do not set sshKeyPaths = [] with only a generateKey keyFile: random keyfiles
  # are not encryption recipients and activation fails with
  # "Error getting data key: 0 successful groups required, got 0".
  sops = {
    age = {
      generateKey = false;
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
    defaultSopsFile = ../secrets/secrets.yaml;
    # Age-only secrets; skip RSA host → GPG import.
    gnupg.sshKeyPaths = lib.mkForce [];
    secrets = {
      acme = {
        format = "dotenv";
        key = "";
        restartUnits = ["acme.service"];
        sopsFile = ../secrets/acme.env;
      };
      authentik = {
        format = "dotenv";
        key = "";
        sopsFile = ../secrets/authentik.env;
      };
      baseDomain = {};
      duckDnsToken = {};
      dummyPassword = {};
      fjr-runner-token = {
        format = "dotenv";
        key = "TOKEN";
        restartUnits = ["forgejo-runner.service"];
        sopsFile = ../secrets/fjr-default.env;
      };
      glr-an = {
        format = "dotenv";
        key = "";
        restartUnits = ["gitlab-runner.service"];
        sopsFile = ../secrets/glr-an.env;
      };
      hermes-env = {
        format = "dotenv";
        key = "";
        restartUnits = ["hermes-agent.service"];
        sopsFile = ../secrets/hermes.env;
      };
      homepage-dashboard = {
        format = "dotenv";
        key = "";
        sopsFile = ../secrets/homepage.env;
      };
      honcho-memory = {
        format = "dotenv";
        key = "";
        restartUnits = [
          "podman-honcho-memory-api.service"
          "podman-honcho-memory-deriver.service"
        ];
        sopsFile = ../secrets/honcho-memory.env;
      };
      letsEncryptEmail = {};
      linkwarden = {
        format = "dotenv";
        key = "";
        sopsFile = ../secrets/linkwarden.env;
      };
      omniroute = {
        format = "dotenv";
        key = "";
        restartUnits = [
          "podman-omniroute-web.service"
        ];
        sopsFile = ../secrets/omniroute.env;
      };
      pangolin = {
        format = "dotenv";
        group = "fossorial";
        key = "";
        owner = "pangolin";
        restartUnits = ["pangolin.service"];
        sopsFile = ../secrets/pangolin.env;
      };
      rclone = {
        format = "ini";
        key = "";
        sopsFile = ../secrets/rclone.ini;
      };
      searxng = {
        format = "dotenv";
        key = "";
        sopsFile = ../secrets/searxng.env;
      };
      smtpEmail = {};
      smtpPassword = {};
      wireless = {
        format = "dotenv";
        key = "";
        sopsFile = ../secrets/wireless.env;
      };
    };
  };
}
