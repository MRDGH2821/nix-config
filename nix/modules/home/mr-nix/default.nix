{...}: {
  # Shared per-user Home Manager config for the interactive account.
  # Identity (home.username / home.homeDirectory) is owned by the consumer
  # stub under hosts/<host>/users/, so the same module serves both the
  # NixOS `mr-nix` user and the standalone Fedora `mr-fw16` account.
  imports = [
    ./dev-tools.nix
    ./git.nix
    ./misc-configs.nix
    ./packages.nix
    ./zed.nix
  ];
}
