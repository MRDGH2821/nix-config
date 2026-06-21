{mylib, ...}: {
  imports = mylib.autoImportModules ./.;
  home.stateVersion = "26.05";
}
