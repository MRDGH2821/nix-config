{lib}: {
  # Function to automatically import all .nix files in a given directory
  # Usage: autoImportModules ./.
  autoImportModules = dir: let
    # Function to check if a file is a .nix file and looks like a module
    # Exclude default.nix, flake.nix, sample files and hidden files.
    isNixModule = name: type: let
      isNix = lib.hasSuffix ".nix" name;
      isHidden = lib.hasPrefix "." name;
      isSample = lib.hasSuffix ".sample.nix" name || lib.hasSuffix ".example.nix" name;
    in
      type
      == "regular"
      && isNix
      && !isHidden
      && name != "default.nix"
      && !isSample
      && name != "flake.nix";

    # Get all matching .nix files in the specified directory
    nixFiles = lib.attrNames (lib.filterAttrs isNixModule (builtins.readDir dir));

    # Convert filenames to paths
    localModules = map (f: dir + "/${f}") nixFiles;
  in
    localModules;
}
