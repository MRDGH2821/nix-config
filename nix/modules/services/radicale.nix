{config, ...}: let
  radicale_dir = "${config.persistant_storage}/radicale/";
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

  # Ensure the directory has correct permissions
  systemd.tmpfiles.rules = [
    "d ${radicale_dir} 0750 radicale radicale -"
    "d ${radicale_dir}/collection-root 0750 radicale radicale -"
  ];
}
