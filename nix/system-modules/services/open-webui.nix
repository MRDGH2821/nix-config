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
      OAUTH_PROVIDER_NAME = "authentik";
      OPENID_REDIRECT_URI = "https://owu.${config.networking.baseDomain}/auth/oidc/callback";
      OPENID_PROVIDER_URL = "https://authentik.${config.networking.baseDomain}/application/o/open-web-ui/.well-known/openid-configuration";
      WEBUI_URL = "https://owu.${config.networking.baseDomain}";
      ENABLE_OAUTH_SIGNUP = true;
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = true;
    };
    environmentFile = config.sops.secrets.open-webui.path;
  };
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "open-webui"
    ];
}
