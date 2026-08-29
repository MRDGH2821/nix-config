# Ported from chezmoi dev-tool dotfiles:
#   dot_config/lazygit/config.yml       -> programs.lazygit.settings
#   dot_config/mise/config.toml         -> programs.mise.globalConfig.tools
#   dot_config/topgrade.toml            -> programs.topgrade.settings
#   dot_config/gallery-dl/config.json   -> programs.gallery-dl.settings
#   dot_config/fastfetch/config.jsonc   -> programs.fastfetch.settings
#   dot_config/tombi/config.toml        -> xdg.configFile."tombi/config.toml"
#
# direnv gets nix-direnv; gh is pinned to the https git protocol.
#
# Deviations from the raw sources:
#   - lazygit `command`: the source hardcodes `/usr/bin/delta`; dropped the
#     absolute path so it resolves `delta` from PATH (same approach as git.nix).
#   - mise `[tools]` is carried over verbatim, including `"aqua:cantino/mcfly"`
#     (a pinned binary via mise, unrelated to the dropped mcfly shell-history
#     integration; the `programs.mcfly` HM module is deliberately NOT used).
#   - fastfetch is loaded from a vendored, comment-stripped JSON: Nix strings
#     cannot express the raw ESC control byte (JSON u001b) that the format
#     strings embed. Two modules with hardcoded foreign paths are removed in
#     that vendored file: the `command` weather module
#     (`/home/arch/.config/fastfetch/weather.sh`) and the `/mnt/ISOz` disk
#     entry. Everything else is kept as-is.
#   - tombi config is copied verbatim to ./files/tombi.toml.
#   - lazygit `os.editPreset` / topgrade: the chezmoi source hardcodes `zed` and
#     an `"Antidot rules" = "antidot update"` command. `zed` is only present on
#     GUI hosts (else lazygit's edit key opens nothing), and `antidot` is not
#     installed here (that topgrade step always failed) — dropped deliberately.
{config, ...}: {
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fastfetch = {
      enable = true;
      settings = builtins.fromJSON (builtins.readFile ./files/fastfetch.json);
    };
    gallery-dl = {
      enable = true;
      settings.extractor = {
        "base-directory" = "./gallery-dl/";
        imgur.directory = [
          "imgur"
          "{album['id']} - {album['title']}"
        ];
        reddit.directory = [
          "reddit"
          "{subreddit}"
          "{title} by {author}"
        ];
      };
    };
    gh = {
      enable = true;
      # git.nix already wires `gh auth git-credential` for github.com and
      # gist.github.com; the HM module's helper defaults on and collides with
      # that (list vs. string merge), so disable it here.
      gitCredentialHelper.enable = false;
      settings.git_protocol = "https";
    };
    lazygit = {
      enable = true;
      settings = {
        git = {
          diffRenderers = [
            {
              colorArg = "always";
              command = ''delta --dark --side-by-side --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"'';
            }
          ];
          merging.manualCommit = true;
          overrideGpg = true;
        };
        gui.sidePanelWidth = 0.3;
        os.editPreset =
          if config.mine.gui.enable
          then "zed"
          else "nano";
      };
    };
    mise = {
      enable = true;
      enableMutableConfig = true; # user still runs `mise use`
      enableZshIntegration = true;
      globalConfig.tools = {
        apm = "latest";
        "aqua:acheronfail/repgrep" = "latest";
        "aqua:cantino/mcfly" = "latest";
        "aqua:google/keep-sorted" = "latest";
        "aqua:kamadorueda/alejandra" = "latest";
        "aqua:numtide/treefmt" = "latest";
        bat = "latest";
        betterleaks = "latest";
        btop = "latest";
        bun = "latest";
        cocogitto = "latest";
        copier = "latest";
        cspell = "latest";
        direnv = "latest";
        fastfetch = "latest";
        fd = "latest";
        fzf = "latest";
        gh = "latest";
        git-cliff = "latest";
        glab = "latest";
        herdr = "latest";
        hk = "latest";
        lazygit = "latest";
        ls-lint = "latest";
        node = "latest";
        "npm:sort-package-json" = "4.0.0";
        prek = "latest";
        prettier = "latest";
        rclone = "latest";
        ripgrep = "latest";
        rtk = "latest";
        rumdl = "0.2.55";
        shellcheck = "latest";
        shfmt = "latest";
        tmux = "latest";
        tombi = "1.4.0";
        topgrade = "latest";
        typos = "latest";
        typstyle = "latest";
        uv = "latest";
        yq = "latest";
        zoxide = "latest";
      };
    };
    topgrade = {
      enable = true;
      settings = {
        commands."Hermes Agent" = "hermes update";
        firmware.upgrade = true;
        git = {
          max_concurrency = 1;
          repos = ["~/Projects/*/*"];
        };
        misc = {
          cleanup = true;
          disable = ["containers"];
          no_self_update = true;
          notify_each_step = false;
        };
      };
    };
  };
  xdg.configFile."tombi/config.toml".source = ./files/tombi.toml;
}
