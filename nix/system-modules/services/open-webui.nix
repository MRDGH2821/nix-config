{
  config,
  lib,
  ...
}: {
  services.open-webui = {
    enable = true;
    openFirewall = true;
    port = 8181;
    environment = {
      ENABLE_OAUTH_SIGNUP = "true";
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
      OAUTH_PROVIDER_NAME = "Authentik";
      OPENID_PROVIDER_URL = "https://authentik.${config.networking.baseDomain}/application/o/open-web-ui/.well-known/openid-configuration";
      OPENID_REDIRECT_URI = "https://owu.${config.networking.baseDomain}/oauth/oidc/callback";
      WEBUI_URL = "https://owu.${config.networking.baseDomain}";
      OAUTH_SCOPES = "openid email profile";
    };
    environmentFile = config.sops.secrets.open-webui.path;
  };
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "open-webui"
    ];
}
