{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.zimfw
    pkgs.oh-my-posh
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    setOptions = [
      "HIST_IGNORE_ALL_DUPES"
      "CORRECT"
      "beep"
      "extendedglob"
      "nomatch"
      "notify"
    ];
    promptInit = ''
      omp_themes_dir="${pkgs.oh-my-posh}/share/oh-my-posh/themes"
      ${builtins.readFile ./zsh-prompt-init.sh}
    '';
  };
}
