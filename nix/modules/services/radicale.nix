let
  radicale_dir = "/etc/nixos/persist/radicale/";
in {
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
        filesystem_folder = radicale_dir;
        hook = ''git add -A && (git diff --cached --quiet || git commit -m "Changes by \"%(user)s\"")'';
      };
    };
  };

  # Ensure the directory is created with correct permissions before service starts
  systemd.services.radicale = {
    serviceConfig = {
      # Bind mount to the persist location
      ReadWritePaths = [radicale_dir];
    };
    preStart = ''
      # Ensure the persist directory exists with correct permissions
      mkdir -p ${radicale_dir}/collection-root
      chown -R radicale:radicale ${radicale_dir}
      # chmod -R 750 ${radicale_dir}
    '';
  };
}
