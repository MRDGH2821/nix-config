# Long-tail dotfiles with no dedicated Home Manager module, vendored verbatim
# from chezmoi (`dot_`/`executable_` prefixes stripped, no templating). Grouped
# here as plain `xdg.configFile` / `home.file` drop-ins.
_: {
  home.file = {
    ".local/bin/cspell-refresh-words" = {
      executable = true;
      source = ./files/bin/cspell-refresh-words;
    };
    ".local/bin/herdr-open" = {
      executable = true;
      source = ./files/bin/herdr-open;
    };
    # CARGO_HOME is `~/.local/share/cargo` (session vars); sets the sccache
    # rustc-wrapper, and `sccache` ships in `home.packages`.
    ".local/share/cargo/config.toml".source = ./files/cargo-config.toml;
    ".shellcheckrc".source = ./files/shellcheckrc;
  };
  xdg.configFile = {
    "copier/settings.yml".source = ./files/copier-settings.yml;
    "herdr/config.toml".source = ./files/herdr.toml;
    # Standalone Fedora account only: a harmless user-level nix.conf override.
    # A future NixOS `fw16` host would set these via `nix.settings` instead.
    "nix/nix.conf".source = ./files/nix.conf;
    "opencode/opencode.json".source = ./files/opencode.json;
    "opencode/tui.json".source = ./files/opencode-tui.json;
    "soar/config.toml".source = ./files/soar-config.toml;
    "soar/packages.toml".source = ./files/soar-packages.toml;
  };
}
