{flake, ...}: {
  imports = flake.lib.autoImportModules ./.;
}
