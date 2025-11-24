{
  services.homepage-dashboard = {
    enable = true;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
    };
    docker = {
      host = "localhost";
      port = 2375;
    };
    openFirewall = true;
  };
}
