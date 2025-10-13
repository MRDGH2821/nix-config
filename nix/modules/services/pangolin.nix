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

    letsEncryptEmail = "";
    baseDomain = "";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
