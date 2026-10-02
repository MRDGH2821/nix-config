# Inject mkUrl / mkSubdomain into every module (host imports flake.modules.nixos.vars).
# baseDomain is read from config.networking.baseDomain inside the helpers — not at call sites.
{
  config,
  flake,
  ...
}: {
  _module.args = flake.lib.mkDomainHelpers {inherit config;};
}
