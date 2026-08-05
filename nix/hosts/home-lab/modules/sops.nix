{
  lib,
  pkgs,
  ...
}: {
  sops = {
    age = {
      # Identity is written by sopsAgeHostKey (host SSH → age).
      generateKey = false;
      keyFile = "/var/lib/sops-nix/key.txt";
      # Prefer keyFile only — avoid dual conversion paths.
      sshKeyPaths = [];
    };
    defaultSopsFile = ../secrets/secrets.yaml;
    # Secrets are age-only; RSA→GPG is unused and noisy.
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
  # Ensure host SSH is converted to an age identity *before* sops-install-secrets.
  # The random /var/lib/sops-nix/key.txt from generateKey=true is not a recipient
  # for our secrets — only admin (age18mhd…) and host SSH → age1t6v85… unlock them.
  system.activationScripts = {
    # sops-nix defines setupSecrets as stringAfter users/groups; pull it after us.
    setupSecrets.deps = ["sopsAgeHostKey"];
    sopsAgeHostKey = {
      deps = [
        "specialfs"
        "users"
        "groups"
      ];
      text = ''
        install -d -m 0700 /var/lib/sops-nix
        ${lib.getExe pkgs.ssh-to-age} -private-key \
          -i /etc/ssh/ssh_host_ed25519_key \
          -o /var/lib/sops-nix/key.txt
        chmod 0600 /var/lib/sops-nix/key.txt
      '';
    };
  };
}
