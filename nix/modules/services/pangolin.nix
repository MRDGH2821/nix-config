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
      domains = {
        domain1 = {
          cert_resolver = "letsencrypt";
          prefer_wildcard_cert = true;
        };
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
