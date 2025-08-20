{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 8090;
      # Bind to all interfaces, not just localhost
      SERVER_HOST = "0.0.0.0";
    };
  };

  # Open firewall port for Stirling PDF
  networking.firewall.allowedTCPPorts = [ 8090 ];
}
