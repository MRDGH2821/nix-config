{
  # This will add secrets.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/secrets.yaml";
  sops.defaultSopsFile = ./secrets/secrets.yaml;

  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;

  # This is the actual specification of the secrets.
  sops.secrets.database_password = {
    # The secret will be available at /run/secrets/database_password
    # The file will be owned by root:root with permissions 0400
  };

  sops.secrets.api_key = {
    # Example: make secret available to a specific user/group
    owner = "nginx";
    group = "nginx";
    mode = "0440";
  };

  sops.secrets.jwt_secret = {
    # Example: place secret in a specific location
    path = "/etc/jwt/secret";
  };

  sops.secrets.pangolin = {
    sopsFile = "./secrets/pangolin.yaml";
    key = "";
  };

  sops.secrets.letsencrypt_email = {};
}
