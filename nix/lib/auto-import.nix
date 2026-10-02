{lib}: {
  autoImportFolders = dir:
    map (f: dir + "/${f}") (
      lib.attrNames (
        lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "." name) (builtins.readDir dir)
      )
    );
  autoImportModules = dir:
    map (f: dir + "/${f}") (
      lib.attrNames (
        lib.filterAttrs (
          name: type:
            type
            == "regular"
            && lib.hasSuffix ".nix" name
            && !lib.hasPrefix "." name
            && name != "default.nix"
            && name != "flake.nix"
            && !lib.hasSuffix ".sample.nix" name
            && !lib.hasSuffix ".example.nix" name
        ) (builtins.readDir dir)
      )
    );
}
