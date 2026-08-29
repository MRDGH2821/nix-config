# Ported from chezmoi `dot_config/zed/{private_settings,keymap,tasks}.json`:
# `private_settings.json` -> `programs.zed-editor.userSettings`, `keymap.json`
# -> `userKeymaps`, `tasks.json` -> `userTasks`, and the `true` entries of
# `auto_install_extensions` -> `programs.zed-editor.extensions`. Config only:
# `package = null` (Zed itself comes from the OS / a later GUI layer).
#
# `mutableUser{Settings,Keymaps,Tasks}` are pinned to `false` for a fully
# declarative port: this Home Manager pin defaults them to `true` (Zed edits
# the files in place via an impure activation-time jq merge), which would leave
# the ported config unmanaged. `false` writes `xdg.configFile."zed/*.json"`
# straight from these attrs.
#
# cspell:ignore unsandboxed Meslo -- verbatim strings from the Zed JSON source
# (`allow_unsandboxed`, the "MesloLGM Nerd Font Mono" font family).
_: {
  programs.zed-editor = {
    enable = true;
    extensions = [
      "basher"
      "cargo-appraiser"
      "colored-zed-icons-theme"
      "cspell"
      "docker-compose"
      "dockerfile"
      "editorconfig"
      "env"
      "git-firefly"
      "gotmpl"
      "ini"
      "json5"
      "just"
      "log"
      "nix"
      "path-server-lsp"
      "powershell"
      "rumdl"
      "ssh-config"
      "tombi"
      "toml"
      "typos"
      "typst"
      "xml"
    ];
    mutableUserKeymaps = false;
    mutableUserSettings = false;
    mutableUserTasks = false;
    package = null;
    userKeymaps = [
      {
        bindings."alt-shift-f" = "editor::Format";
        context = "Editor";
      }
      {
        bindings = {
          "ctrl-enter" = [
            "terminal::SendKeystroke"
            "ctrl-enter"
          ];
          "ctrl-p" = [
            "terminal::SendKeystroke"
            "ctrl-p"
          ];
          "ctrl-s" = [
            "terminal::SendKeystroke"
            "ctrl-s"
          ];
          "ctrl-t" = [
            "terminal::SendKeystroke"
            "ctrl-t"
          ];
          "ctrl-x" = [
            "terminal::SendKeystroke"
            "ctrl-x"
          ];
        };
        context = "Terminal";
      }
      {
        bindings."alt-z" = "editor::ToggleSoftWrap";
        context = "(Editor && mode == full)";
      }
      {
        bindings = {
          "alt-g" = [
            "task::Spawn"
            {
              reveal_target = "center";
              task_name = "Start Lazygit";
            }
          ];
          "alt-m" = [
            "task::Spawn"
            {
              task_name = "Meld file diff";
            }
          ];
          "alt-shift-g" = [
            "task::Spawn"
            {
              task_name = "Open Sourcegit";
            }
          ];
          "alt-shift-m" = [
            "task::Spawn"
            {
              task_name = "Meld dir diff";
            }
          ];
        };
        context = "Workspace";
      }
      {
        bindings."super-shift-f" = [
          "task::Spawn"
          {
            reveal_target = "center";
            task_name = "Format files";
          }
        ];
        context = "Workspace";
      }
      {
        bindings."shift-enter" = [
          "terminal::SendText"
          (builtins.fromJSON ''"\u001b\r"'')
        ];
        context = "Terminal";
      }
    ];
    userSettings = {
      agent = {
        default_model = {
          effort = "high";
          enable_thinking = true;
          model = "claude-sonnet-5";
          provider = "zed.dev";
        };
        default_profile = "write";
        dock = "right";
        model_parameters = [];
        sandbox_permissions.allow_unsandboxed = true;
        sidebar_side = "right";
        terminal_init_command = "herdr-open";
        tool_permissions.tools = {
          fetch.default = "allow";
          "mcp:NixOS MCP:nix".default = "allow";
          terminal.always_allow = [
            {pattern = "^cat\\b";}
            {pattern = "^grep\\b";}
            {pattern = "^head\\b";}
            {pattern = "^sed\\b";}
            {pattern = "^git\\s+check-ignore(\\s|$)";}
            {pattern = "^echo\\s+===(\\s|$)";}
            {pattern = "^echo\\b";}
            {pattern = "^grep\\s+\\^-(\\s|$)";}
            {pattern = "^sort\\b";}
            {pattern = "^uniq\\b";}
            {pattern = "^wc\\b";}
            {pattern = "^git\\s+ls-files(\\s|$)";}
            {pattern = "^ls\\s+nix/checks/(\\s|$)";}
            {pattern = "^git\\s+ls-tree(\\s|$)";}
            {pattern = "^awk\\s+\\{print(\\s|$)";}
            {pattern = "^ls\\b";}
          ];
        };
      };
      agent_servers = {
        "antigravity-acp".type = "registry";
        cursor = {
          default_config_options = {
            mode = "agent";
            model = "default";
          };
          type = "registry";
        };
        hermes = {
          args = ["acp"];
          command = "hermes";
          type = "custom";
        };
        opencode = {
          args = ["acp"];
          command = "opencode";
          type = "custom";
        };
      };
      auto_install_extensions = {
        basher = true;
        "cargo-appraiser" = true;
        "colored-zed-icons-theme" = true;
        cspell = true;
        "docker-compose" = true;
        dockerfile = true;
        editorconfig = true;
        env = true;
        "git-firefly" = true;
        gotmpl = true;
        ini = true;
        json5 = true;
        just = true;
        log = true;
        nix = true;
        "path-server-lsp" = true;
        powershell = true;
        rumdl = true;
        "ssh-config" = true;
        tombi = true;
        toml = true;
        typos = true;
        typst = true;
        xml = true;
      };
      autosave.after_delay.milliseconds = 1000;
      base_keymap = "Atom";
      buffer_font_family = "MesloLGM Nerd Font Mono";
      buffer_font_size = 16;
      calls.mute_on_join = true;
      cli_default_open_behavior = "new_window";
      collaboration_panel.dock = "left";
      colorize_brackets = true;
      context_servers."mcp-nixos" = {
        args = ["mcp-nixos"];
        command = "uvx";
        enabled = true;
        remote = false;
      };
      diagnostics.inline.enabled = true;
      edit_predictions.provider = "zed";
      file_types = {
        JSONC = [
          "**/.zed/**/*.json"
          "**/zed/**/*.json"
          "**/Zed/**/*.json"
        ];
        "Shell Script" = [
          ".envrc"
          ".envrc.local"
        ];
        env = [
          ".env"
          ".env.*"
        ];
        ini = [
          "private_dolphinrc"
          "private_konsolerc"
          ".editorconfig"
        ];
      };
      format_on_save = "off";
      git_panel = {
        dock = "left";
        tree_view = true;
      };
      icon_theme = {
        dark = "Colored Zed Icons Theme Dark";
        light = "Colored Zed Icons Theme Light";
        mode = "system";
      };
      languages = {
        Just.formatter = "language_server";
        Nix.formatter.external = {
          arguments = [
            "--quiet"
            "--"
          ];
          command = "alejandra";
        };
        "Shell Script".formatter.external = {
          arguments = [
            "--filename"
            "{buffer_path}"
            "--indent"
            "2"
          ];
          command = "shfmt";
        };
        Typst.formatter = [
          {
            external = {
              arguments = [
                "--use-std-in"
                "-s"
                "default"
                "--use-std-out"
              ];
              command = "prettypst";
            };
          }
          {
            external = {
              arguments = [
                "--use-std-in"
                "-s"
                "otbs"
                "--use-std-out"
              ];
              command = "prettypst";
            };
          }
          "language_server"
        ];
        XML.formatter.external = {
          arguments = [
            "--format"
            "{buffer_path}"
          ];
          command = "xmllint";
        };
      };
      load_direnv = "direct";
      lsp = {
        "json-language-server".settings.json.schemas = [
          {
            fileMatch = [
              ".prettierrc.json"
              ".prettierrc.json5"
              ".prettierrc.jsonc"
              ".prettierrc"
            ];
            url = "https://www.schemastore.org/prettierrc.json";
          }
          {
            fileMatch = [
              "*/.cspell.config.json"
              "*/.cspell.config.jsonc"
              "*/.cspell.json"
              "*/.cspell.jsonc"
              "*/cspell.config.json"
              "*/cspell.config.jsonc"
              "*/cspell.json"
              "*/cspell.jsonc"
            ];
            url = "https://raw.githubusercontent.com/streetsidesoftware/cspell/main/cspell.schema.json";
          }
          {
            fileMatch = [
              ".v8rrc"
              ".v8rrc.json"
              ".v8rrc.yaml"
              ".v8rrc.yml"
            ];
            url = "https://raw.githubusercontent.com/chris48s/v8r/main/config-schema.json";
          }
          {
            fileMatch = [".jscpd.json"];
            url = "https://www.schemastore.org/jscpd.json";
          }
          {
            fileMatch = [".markdownlint.json"];
            url = "https://raw.githubusercontent.com/DavidAnson/markdownlint/main/schema/markdownlint-config-schema.json";
          }
        ];
        nil.settings.nix.flake = {
          autoArchive = true;
          autoEvalInputs = true;
        };
        tinymist = {
          initialization_options.preview.background.enabled = true;
          settings."preview.invertColors" = "auto";
        };
        "yaml-language-server".settings.yaml.schemaStore = {
          completion = true;
          enable = true;
          hover = true;
        };
      };
      outline_panel.dock = "left";
      prettier = {
        allowed = true;
        plugins = ["prettier-plugin-packagejson"];
      };
      project_panel = {
        dock = "left";
        hide_gitignore = false;
      };
      redact_private_values = false;
      tab_size = 2;
      tabs = {
        file_icons = true;
        git_status = true;
      };
      telemetry = {
        anthropic_retention = true;
        diagnostics = true;
        metrics = true;
      };
      terminal.copy_on_select = true;
      theme = {
        dark = "Ayu Dark";
        light = "Ayu Light";
        mode = "system";
      };
      title_bar = {
        show_branch_status_icon = true;
        show_menus = true;
      };
      toolbar.code_actions = true;
      ui_font_family = "MesloLGM Nerd Font Mono";
      ui_font_size = 16;
    };
    userTasks = [
      {
        allow_concurrent_runs = false;
        command = "cspell-refresh-words";
        hide = "on_success";
        label = "cspell: refresh words";
        reveal = "always";
        save = "all";
        show_command = true;
        show_summary = true;
        use_new_terminal = false;
      }
      {
        allow_concurrent_runs = false;
        args = [
          "-c"
          "'nix fmt || mise run fmt || hk fix || treefmt -vv || prettier --write .'"
        ];
        command = "sh";
        hide = "on_success";
        label = "Format files";
        reveal_target = "center";
        show_command = true;
        tags = ["format"];
      }
      {
        args = [
          "difftool"
          "--dir-diff"
        ];
        command = "git";
        hide = "on_success";
        label = "Meld dir diff";
        tags = ["git"];
      }
      {
        args = [
          "difftool"
          "\"$ZED_FILE\""
          "-y"
        ];
        command = "git";
        hide = "on_success";
        label = "Meld file diff";
        tags = ["git"];
      }
      {
        args = [
          "-p"
          "\"$ZED_WORKTREE_ROOT\""
        ];
        command = "lazygit";
        hide = "on_success";
        label = "Start Lazygit";
        reveal_target = "center";
        tags = ["git"];
      }
      {
        args = ["\"$ZED_WORKTREE_ROOT\""];
        command = "SourceGit";
        hide = "always";
        label = "Open Sourcegit";
        tags = ["git"];
      }
      {
        args = [
          "copy"
          "gh:MRDGH2821/copier-mr-minimal"
          "\"$ZED_WORKTREE_ROOT\""
        ];
        command = "copier";
        hide = "on_success";
        label = "Initialise with copier template";
        tags = ["git"];
      }
      {
        args = [
          "-c"
          "'copier check-update -q || copier update'"
        ];
        command = "sh";
        hide = "on_success";
        label = "Update copier template";
        tags = ["git"];
      }
      {
        args = ["mega-linter-runner"];
        command = "bunx";
        hide = "on_success";
        label = "Run Mega Linter";
        reveal_target = "center";
        tags = ["lint"];
      }
    ];
  };
}
