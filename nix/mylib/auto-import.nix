{ lib }:

{
  # Function to automatically import all .nix files in a given directory
  # Usage: autoImportModules ./.
  autoImportModules =
    dir:
    let
      # Function to check if a file is a .nix file and not default.nix
      isNixModule = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";

      # Get all .nix files in the specified directory
      nixFiles = lib.attrNames (lib.filterAttrs isNixModule (builtins.readDir dir));

      # Convert filenames to paths
      localModules = map (f: dir + "/${f}") nixFiles;
    in
    localModules;
}
