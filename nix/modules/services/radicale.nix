{
  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = ["0.0.0.0:5232" "[::]:5232"];
      };
      auth = {
        type = "http_x_remote_user";
      };
      storage = {
        filesystem_folder = "/etc/nixos/persist/radicale/";
        hook = ''git add -A && (git diff --cached --quiet || git commit -m "Changes by \"%(user)s\"")'';
      };
    };
  };

  # Ensure the directory is created with correct permissions before service starts
  systemd.services.radicale = {
    serviceConfig = {
      # Create the directory structure automatically
      StateDirectory = "radicale";
      StateDirectoryMode = "0750";
      # Bind mount to the persist location
      ReadWritePaths = ["/etc/nixos/persist/radicale"];
    };
    preStart = ''
      # Ensure the persist directory exists with correct permissions
      mkdir -p /etc/nixos/persist/radicale/collection-root
      chown -R radicale:radicale /etc/nixos/persist/radicale
      chmod -R 750 /etc/nixos/persist/radicale
    '';
  };
}
