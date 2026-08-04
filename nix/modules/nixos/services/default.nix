_: {mylib, ...}: {
  imports = mylib.autoImportModules ./.;
}
