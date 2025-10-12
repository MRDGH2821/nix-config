{ pkgs, config, ... }:
{
  # NOTE: replace the placeholders below with real values for your deployment
  # (baseDomain and letsEncryptEmail). The environment file will be created
  # from the sops secrets mapping `sops.secrets.pangolin_env`.

  environment.systemPackages = with pkgs; [ fosrl-pangolin ];

  services.pangolin = {
    enable = true;
    openFirewall = true;

    # Email for Let's Encrypt registration — replace with your real email
    letsEncryptEmail = config.sops.secrets.letsencrypt_email;

    # Path to the environment file the pangolin service expects.
    # We will create this file from a sops secret below.
    environmentFile = "/run/secrets/pangolin";
  };

}
