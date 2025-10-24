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
    settings = {
      app = {
        save_logs = true;
      };
    };
    environmentFile = config.sops.secrets.pangolin.path;
    dnsProvider = "duckdns";
  };

  services.traefik = {
    environmentFiles = [
      config.sops.secrets.traefik.path
      config.sops.secrets.acme.path
    ];
  };
}
