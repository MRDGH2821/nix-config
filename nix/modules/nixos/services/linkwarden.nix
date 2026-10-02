{config, ...}: {
  services.linkwarden = {
    database.createLocally = true;
    enable = true;
    environment = {
      AUTHENTIK_ISSUER = "https://authentik.${config.networking.baseDomain}/application/o/linkwarden";
      NEXTAUTH_URL = "https://linkwarden.${config.networking.baseDomain}/api/v1/auth";
      NEXT_PUBLIC_AUTHENTIK_ENABLED = "true";
      NEXT_PUBLIC_EMAIL_PROVIDER = "true";
      NEXT_PUBLIC_OLLAMA_ENDPOINT_URL = "http://localhost:11434";
      OLLAMA_MODEL = "phi4-mini:latest";
    };
    environmentFile = config.sops.templates.linkwarden.path;
    openFirewall = true;
    port = 3060;
  };
  sops.templates.linkwarden.content = ''
    ${config.sops.placeholder.linkwarden}

    EMAIL_FROM=${config.networking.smtp.email}
    EMAIL_SERVER=smtp://${config.networking.smtp.username}:${config.sops.placeholder.smtpPassword}@${config.networking.smtp.host}:${toString config.networking.smtp.port}
  '';
}
