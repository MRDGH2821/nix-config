{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];

  services.pangolin = {
    enable = true;
    openFirewall = true;

    letsEncryptEmail = "";
    baseDomain = "";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
