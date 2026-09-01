# Ported from chezmoi `dot_config/git/config`: identity, delta pager, GPG
# signing, work/uni `includeIf` splits and the gh/glab/libsecret/oauth
# credential helper stack. The `config-axisnexa` / `config-unimelb` include
# targets are not managed here; the `includeIf` entries no-op until those
# files exist.
_: {
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
        dark = true;
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
        user = {
          email = "ask.mrdgh2821@outlook.com";
          name = "MRDGH2821";
        };
      };
      # Public GPG key id (not a secret); chezmoi dot_config/git/config -> [user].signingkey.
      signing = {
        key = "1915CBA05A598D01"; # pragma: allowlist secret
        signByDefault = true;
      };
    };
  };
}
