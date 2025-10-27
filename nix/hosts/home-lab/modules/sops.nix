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
  sops.secrets.traefik = {
    sopsFile = ../secrets/traefik.env;
    format = "dotenv";
    key = "";
    restartUnits = ["traefik.service"];
  };
  sops.secrets.bewcloud = {
    sopsFile = ../secrets/bewcloud.env;
    format = "dotenv";
    key = "";
  };
}
