{pkgs, ...}: let
  promptInitScript = pkgs.writeShellScript "zsh-prompt-init" ''
    omp_themes_dir="${pkgs.oh-my-posh}/share/oh-my-posh/themes"
    omp_themes=($omp_themes_dir/*.json)
    num_files=''${#omp_themes[@]}
    random_index=$((RANDOM % num_files))
    random_omp_theme=''${omp_themes[$random_index]}
    eval "$(oh-my-posh init zsh --config $random_omp_theme)"
    SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
  '';
in {
  environment.systemPackages = with pkgs; [
    zimfw
    oh-my-posh
  ];
  programs.zsh = {
    autosuggestions = {
      enable = true;
      extraConfig."ZSH_AUTOSUGGEST_MANUAL_REBIND" = "1";
    };
    enable = true;
    enableCompletion = true;
    promptInit = builtins.readFile promptInitScript;
    setOptions = [
      "HIST_IGNORE_ALL_DUPES"
      "CORRECT"
      "beep"
      "extendedglob"
      "nomatch"
      "notify"
    ];
    shellInit = ''
      bindkey -e
      zmodload -F zsh/terminfo +p:terminfo
    '';
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
      ];
    };
  };
}
