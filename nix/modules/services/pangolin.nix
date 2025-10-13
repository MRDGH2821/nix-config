{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];
  boot.kernelModules = ["wireguard"];

  services.pangolin = {
    enable = true;
    openFirewall = true;

    letsEncryptEmail = "letsencrypt@example.com";
    baseDomain = "pangolin.example.com";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
