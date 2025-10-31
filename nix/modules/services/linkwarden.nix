{config, ...}: {
  sops.templates.linkwarden = {
    content = ''
      ${config.sops.placeholder.linkwarden}

      EMAIL_FROM=${config.networking.smtp.email}
      EMAIL_SERVER=smtp://${config.networking.smtp.username}:${config.sops.placeholder.smtpPassword}@${config.networking.smtp.host}:${config.networking.smtp.port}
    '';
  };
  services.linkwarden = {
    enable = true;
    port = 3060;
    database.createLocally = true;
    services.linkwarden.openFirewall = true;
    environment = {
      NEXT_PUBLIC_OLLAMA_ENDPOINT_URL = "http://localhost:11434";
      OLLAMA_MODEL = "phi3:mini-4k";
      NEXT_PUBLIC_EMAIL_PROVIDER = true;
      NEXT_PUBLIC_AUTHENTIK_ENABLED = true;
      AUTHENTIK_ISSUER = "https://authentik.${config.networking.baseDomain}/application/o/linkwarden";
    };
    environmentFile = config.sops.templates.linkwarden.path;
  };
}
