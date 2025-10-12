{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];

  services.pangolin = {
    enable = true;
    openFirewall = true;
    # Use placeholder to substitute the actual secret value at runtime
    letsEncryptEmail = "${config.sops.placeholder.letsEncryptEmail}";
    baseDomain = "${config.sops.placeholder.baseDomain}";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
