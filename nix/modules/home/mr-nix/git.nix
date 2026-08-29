# Ported from chezmoi `dot_config/git/config`: identity via the `mine.git`
# option (real values live in the per-host user stub), delta pager, GPG
# signing, work/uni `includeIf` splits and the gh/glab/libsecret/oauth
# credential helper stack. The `config-axisnexa` / `config-unimelb` include
# targets are not managed here; the `includeIf` entries no-op until those
# files exist.
{
  config,
  lib,
  ...
}: let
  cfg = config.mine.git;
in {
  config = {
    # git hook templates referenced by init.templateDir (vendored from chezmoi,
    # `executable_` prefix stripped).
    home.file = {
      ".config/git/templates/hooks/commit-msg" = {
        executable = true;
        source = ./files/git/templates/hooks/commit-msg;
      };
      ".config/git/templates/hooks/pre-commit" = {
        executable = true;
        source = ./files/git/templates/hooks/pre-commit;
      };
    };
    programs = {
      # delta wires itself as git's pager (blame/diff/log/show) and interactive
      # diff filter, replacing chezmoi's manual `core.pager`.
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          line-numbers = true;
          navigate = true;
          side-by-side = true;
          syntax-theme = "Dracula";
        };
      };
      git = {
        enable = true;
        includes = [
          {
            condition = "hasconfig:remote.*.url:https://gitlab.com/axisnexa/**";
            path = "~/.config/git/config-axisnexa";
          }
          {
            condition = "gitdir/i:**/AxisNexa/";
            path = "~/.config/git/config-axisnexa";
          }
          {
            condition = "gitdir/i:**/UniMelb/";
            path = "~/.config/git/config-unimelb";
          }
        ];
        settings = {
          core = {
            autocrlf = false;
            editor = "zed -n --wait";
          };
          credential = {
            helper = [
              "cache --timeout 21600"
              "libsecret"
              "oauth"
            ];
            "https://gist.github.com".helper = "!gh auth git-credential";
            "https://github.com".helper = "!gh auth git-credential";
            "https://gitlab.com".helper = "!glab auth git-credential";
          };
          init = {
            defaultBranch = "main";
            templateDir = "~/.config/git/templates";
          };
          log.showSignature = true;
          merge = {
            ff = "only";
            guitool = "meld";
          };
          push.followTags = true;
          tag.forceSignAnnotated = true;
          user = lib.mkMerge [
            (lib.mkIf (cfg.userName != "") {name = cfg.userName;})
            (lib.mkIf (cfg.userEmail != "") {email = cfg.userEmail;})
          ];
        };
        signing = lib.mkIf (cfg.signingKey != "") {
          key = cfg.signingKey;
          signByDefault = true;
        };
      };
    };
  };
  options.mine.git = {
    signingKey = lib.mkOption {
      default = "";
      description = "GPG signing key id/fingerprint for commit/tag signing; empty disables signing config.";
      type = lib.types.str;
    };
    userEmail = lib.mkOption {
      default = "";
      description = "git user.email; empty leaves it unmanaged.";
      type = lib.types.str;
    };
    userName = lib.mkOption {
      default = "";
      description = "git user.name; empty leaves it unmanaged.";
      type = lib.types.str;
    };
  };
}
