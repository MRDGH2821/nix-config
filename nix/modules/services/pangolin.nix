{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [fosrl-pangolin];

  services.pangolin = {
    enable = true;
    openFirewall = true;
    # Use sops placeholders (strings substituted at activation time). No .path here.
    letsEncryptEmail =
      if builtins.hasAttr "letsEncryptEmail" config.sops.placeholder
      then config.sops.placeholder.letsEncryptEmail
      else builtins.throw "Missing sops placeholder 'letsEncryptEmail' (add as top-level key in secrets file).";

    baseDomain =
      if builtins.hasAttr "baseDomain" config.sops.placeholder
      then config.sops.placeholder.baseDomain
      else builtins.throw "Missing sops placeholder 'baseDomain' (add as top-level key in secrets file).";
    environmentFile = config.sops.secrets.pangolin.path;
  };
}
