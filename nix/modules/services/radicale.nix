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
}
