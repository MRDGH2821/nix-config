{
  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/secrets.yaml";
  sops.defaultSopsFile = ../secrets/secrets.yaml;

  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;

  sops.secrets.baseDomain = {};
  sops.secrets.duckDnsToken = {};
  sops.secrets.dummyPassword = {};
  sops.secrets.letsEncryptEmail = {};
  sops.secrets.smtpEmail = {};
  sops.secrets.smtpPassword = {};

  sops.secrets.peertubeSmtpPassword = {
    owner = "peertube";
    group = "peertube";
    restartUnits = ["peertube.service"];
    key = "smtpPassword";
  };
  sops.secrets.peertubeSecret = {
    owner = "peertube";
    group = "peertube";
    restartUnits = ["peertube.service"];
  };

  sops.secrets.acme = {
    sopsFile = ../secrets/acme.env;
    format = "dotenv";
    key = "";
    restartUnits = ["acme.service"];
  };

  sops.secrets.pangolin = {
    sopsFile = ../secrets/pangolin.env;
    format = "dotenv";
    key = "";
    restartUnits = ["pangolin.service"];
    owner = "pangolin";
    group = "fossorial";
  };

  sops.secrets.bewcloud = {
    sopsFile = ../secrets/bewcloud.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets.authentik = {
    sopsFile = ../secrets/authentik.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets.linkwarden = {
    sopsFile = ../secrets/linkwarden.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets.wireless = {
    sopsFile = ../secrets/wireless.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets.homepage-dashboard = {
    sopsFile = ../secrets/homepage.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets.rclone = {
    sopsFile = ../secrets/rclone.ini;
    format = "ini";
    key = "";
  };

  sops.secrets.ocis = {
    sopsFile = ../secrets/ocis.env;
    format = "dotenv";
    key = "";
  };

  sops.secrets."ocis.yaml" = {
    sopsFile = ../secrets/ocis.yaml;
    format = "yaml";
    key = "";
    path = "/var/lib/ocis/config/ocis.yaml";
    owner = "ocis";
  };
}
