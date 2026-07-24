{pkgs, ...}: {
  programs = {
    actionlint.enable = true;
    alejandra = {
      enable = true;
      priority = 10;
    };
    beautysh.enable = true;
    deadnix.enable = true;
    djlint.enable = true;
    dockerfmt.enable = true;
    dockfmt.enable = true;
    dos2unix.enable = true;
    flake-edit.enable = true;
    genemichaels.enable = true;
    just.enable = true;
    keep-sorted.enable = true;
    nbstripout.enable = true;
    nixf-diagnose.enable = true;
    nixfmt = {
      enable = true;
      priority = 1;
    };
    nixpkgs-fmt.enable = false;
    oxfmt = {
      enable = true;
      priority = 80;
    };
    pedantix = {
      enable = true;
      settings.attrs = {
        blank-lines = 0;
        flatten = true;
        merge = true;
      };
    };
    prettier = {
      enable = true;
      excludes = [
        # keep-sorted start
        "*.*ignore"
        "*.aac"
        "*.docx"
        "*.envrc"
        "*.jinja"
        "*.jpg"
        "*.lock"
        "*.mp4"
        "*.nix"
        "*.pdf"
        "*.png"
        "*.pptx"
        "*.py"
        "*.toml"
        "*.txt"
        "*.typ"
        ".envrc"
        "LICENCE"
        "LICENSE"
        "justfile"
        # keep-sorted end
      ];
      includes = ["*"];
      priority = 100;
    };
    ruff-check = {
      enable = true;
      priority = 8;
    };
    ruff-format = {
      enable = true;
      priority = 9;
    };
    shellcheck.enable = true;
    shfmt.enable = true;
    sqlfluff.enable = true;
    sqlfluff-lint.enable = true;
    statix.enable = true;
    taplo.enable = true;
    toml-sort = {
      enable = true;
      priority = 0;
    };
    typos = {
      enable = true;
      excludes = [
        # keep-sorted start
        "**/.cspell.json"
        ".cspell.json"
        "CHANGELOG.md"
        # keep-sorted end
      ];
    };
    typstyle = {
      enable = true;
      priority = 1;
    };
    xmllint.enable = true;
    yamllint = {
      enable = true;
      priority = 9;
      settings = {
        extends = "default";
        rules = {
          comments = "disable";
          line-length = "disable";
          truthy = "disable";
        };
      };
    };
    zizmor.enable = true;
  };
  projectRootFile = "flake.nix";
  settings = {
    "allow-missing-formatter" = true;
    excludes = ["**/skills/**"];
    formatter = {
      cspell-sort = {
        command = "${pkgs.lib.getExe pkgs.yq-go}";
        includes = [
          # keep-sorted start
          "**/.CSpell*"
          "**/.cspell*"
          "**/cSpell*"
          "**/cspell*"
          ".CSpell*"
          ".cspell*"
          "cspell*"
          # keep-sorted end
        ];
        no-positional-arg-support = true;
        options = [
          "-i"
          ".words|= sort_by(downcase)|.ignorePaths|=sort_by(downcase)"
        ];
        priority = 9;
      };
      prettypst-default = {
        command = "${pkgs.lib.getExe pkgs.prettypst}";
        includes = ["*.typ"];
        no-positional-arg-support = true;
        options = [
          "-s"
          "default"
        ];
        priority = 2;
      };
      prettypst-otbs = {
        command = "${pkgs.lib.getExe pkgs.prettypst}";
        includes = ["*.typ"];
        no-positional-arg-support = true;
        options = [
          "-s"
          "otbs"
        ];
        priority = 3;
      };
      sort-markdown-tables = {
        command = "smt";
        includes = ["*.md"];
        options = ["-i"];
        priority = 2;
      };
      tombi-format = {
        command = "${pkgs.lib.getExe pkgs.tombi}";
        includes = ["*.toml"];
        options = [
          "format"
          "--offline"
        ];
        priority = 11;
      };
      toml-sort.options = [
        "--sort-inline-tables"
        "--sort-table-keys"
      ];
      yamlfix = {
        command = "${pkgs.lib.getExe pkgs.yamlfix}";
        includes = [
          # keep-sorted start
          "*.yaml"
          "*.yml"
          # keep-sorted end
        ];
        priority = 8;
      };
      yq-key-sort = {
        command = "${pkgs.lib.getExe pkgs.yq-go}";
        includes = [
          # keep-sorted start
          "*.json"
          "*.yaml"
          "*.yml"
          # keep-sorted end
        ];
        no-positional-arg-support = true;
        options = [
          "-P"
          "-i"
          "sort_keys(..)"
        ];
        priority = 0;
      };
    };
  };
}
