{
  sops = {
    age = {
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will automatically import SSH keys as age keys
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
    # This will add secrets.yml to the nix store
    # You can avoid this by adding a string to the full path instead, i.e.
    # sops.defaultSopsFile = "/root/.sops/secrets/secrets.yaml";
    defaultSopsFile = ../secrets/secrets.yaml;
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
