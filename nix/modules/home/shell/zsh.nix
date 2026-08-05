# Port of former NixOS zimfw+zsh stack to Home Manager + oh-my-zsh.
# Native HM features cover completion, autosuggestions, highlighting, and
# history-substring-search (were separate zim modules).
{
  lib,
  pkgs,
  ...
}: {
  programs = {
    oh-my-posh = {
      enable = true;
      # Random theme each shell — do not use fixed useTheme / zsh integration.
      enableZshIntegration = false;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      defaultKeymap = "emacs";

      autosuggestion.enable = true;
      history = {
        ignoreAllDups = true;
        share = true;
      };
      historySubstringSearch.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
        ];
      };

      # zimrc ohmyzsh/* plugins + git (zim `git` module)
      oh-my-zsh = {
        enable = true;
        # Prompt comes from oh-my-posh, not an omz theme.
        theme = "";
        plugins = [
          "git"
          "alias-finder"
          "common-aliases"
          "command-not-found"
          "docker"
          "docker-compose"
          "fnm"
          "gh"
          "ssh"
          "systemd"
          "tldr"
          "vscode"
        ];
      };

      initContent = lib.mkOrder 550 ''
        zmodload -F zsh/terminfo +p:terminfo
        setopt CORRECT BEEP EXTENDED_GLOB NOMATCH NOTIFY
        ZSH_AUTOSUGGEST_MANUAL_REBIND=1
        SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

        # Random oh-my-posh theme (replaces zim asciiship + former system promptInit)
        omp_themes_dir="${pkgs.oh-my-posh}/share/oh-my-posh/themes"
        omp_themes=($omp_themes_dir/*.json(N))
        if (( ''${#omp_themes[@]} > 0 )); then
          random_omp_theme=''${omp_themes[$((RANDOM % ''${#omp_themes[@]} + 1))]}
          eval "$(${lib.getExe pkgs.oh-my-posh} init zsh --config "$random_omp_theme")"
        fi

        touchfile() { mkdir -p "$(dirname "$1")" && touch "$1" && echo "$1"; }
      '';
    };
  };
}
