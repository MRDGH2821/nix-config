{config, ...}: let
  # peertube-dir = "${config.persistent_storage}/peertube/storage";
in {
  # Create necessary directories for peertube
  # systemd.tmpfiles.rules = [
  #   "d ${peertube-dir} 0755 peertube peertube -"
  #   "d ${peertube-dir}/tmp 0755 peertube peertube -"
  #   "d ${peertube-dir}/tmp-persistent 0755 peertube peertube -"
  #   "d ${peertube-dir}/bin 0755 peertube peertube -"
  #   "d ${peertube-dir}/avatars 0755 peertube peertube -"
  #   "d ${peertube-dir}/web-videos 0755 peertube peertube -"
  #   "d ${peertube-dir}/streaming-playlists 0755 peertube peertube -"
  #   "d ${peertube-dir}/original-video-files 0755 peertube peertube -"
  #   "d ${peertube-dir}/redundancy 0755 peertube peertube -"
  #   "d ${peertube-dir}/logs 0755 peertube peertube -"
  #   "d ${peertube-dir}/previews 0755 peertube peertube -"
  #   "d ${peertube-dir}/thumbnails 0755 peertube peertube -"
  #   "d ${peertube-dir}/storyboards 0755 peertube peertube -"
  #   "d ${peertube-dir}/torrents 0755 peertube peertube -"
  #   "d ${peertube-dir}/captions 0755 peertube peertube -"
  #   "d ${peertube-dir}/cache 0755 peertube peertube -"
  #   "d ${peertube-dir}/plugins 0755 peertube peertube -"
  #   "d ${peertube-dir}/well-known 0755 peertube peertube -"
  #   "d ${peertube-dir}/uploads 0755 peertube peertube -"
  #   "d ${peertube-dir}/client-overrides 0755 peertube peertube -"
  # ];

  sops.templates."peertube.env" = {
    content = ''
      NODE_ENV=production
      PT_INITIAL_ROOT_PASSWORD=${config.sops.placeholder.dummyPassword}

    '';
  };
  services.peertube = {
    enable = true;
    redis.createLocally = true;
    database.createLocally = true;
    localDomain = "peertube.${config.networking.baseDomain}";
    listenWeb = 9050;
    listenHttp = 9050;
    settings = {
      video_transcription.enabled = true;
      smtp = {
        transport = "smtp";
        hostname = config.networking.smtp.host;
        port = config.networking.smtp.port;
        username = config.networking.smtp.email;
        password = config.sops.placeholder.peertubeSmtpPassword;
        tls = true;
        disable_starttls = false;
        from_address = config.networking.smtp.email;
      };
      # storage = {
      #   tmp = "${peertube-dir}/tmp/";
      #   tmp_persistent = "${peertube-dir}/tmp-persistent/"; # As tmp but the directory is not cleaned up between PeerTube restarts
      #   bin = "${peertube-dir}/bin/";
      #   avatars = "${peertube-dir}/avatars/";
      #   web_videos = "${peertube-dir}/web-videos/";
      #   streaming_playlists = "${peertube-dir}/streaming-playlists/";
      #   original_video_files = "${peertube-dir}/original-video-files/";
      #   redundancy = "${peertube-dir}/redundancy/";
      #   logs = "${peertube-dir}/logs/";
      #   previews = "${peertube-dir}/previews/";
      #   thumbnails = "${peertube-dir}/thumbnails/";
      #   storyboards = "${peertube-dir}/storyboards/";
      #   torrents = "${peertube-dir}/torrents/";
      #   captions = "${peertube-dir}/captions/";
      #   cache = "${peertube-dir}/cache/";
      #   plugins = "${peertube-dir}/plugins/";
      #   well_known = "${peertube-dir}/well-known/"; # Various admin/user uploads that are not suitable for the folders above
      #   uploads = "${peertube-dir}/uploads/"; # Overridable client files in client/dist/assets/images:
      #   # - default-avatar-account-48x48.png
      #   # - default-avatar-account.png
      #   # - default-avatar-video-channel-48x48.png
      #   # - default-avatar-video-channel.png
      #   # - default-playlist.jpg
      #   # Could contain for example "assets/images/default-playlist.jpg"
      #   # If the file exists, peertube will serve it
      #   # If not, peertube will fallback to the default file
      #   client_overrides = "${peertube-dir}/client-overrides/";
      # };
    };
    smtp.passwordFile = config.sops.secrets.peertubeSmtpPassword.path;
    serviceEnvironmentFile = config.sops.templates."peertube.env".path;
    secrets.secretsFile = config.sops.secrets.peertubeSecret.path;
  };
}
