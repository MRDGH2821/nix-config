{ pkgs, config, ... }:
{
  environment.systemPackages = with pkgs; [ fosrl-pangolin ];

  services.pangolin = {
    enable = true;
    openFirewall = true;
    letsEncryptEmail = config.sops.secrets.letsencrypt_email;
    environmentFile = config.sops.secrets.pangolin.path;
  };

}
