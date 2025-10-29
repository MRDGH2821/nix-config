{pkgs, ...}: let
  promptInitScript = pkgs.writeShellScript "zsh-prompt-init" ''
    # Provide path to oh-my-posh installed themes
    omp_themes_dir="${pkgs.oh-my-posh}/share/oh-my-posh/themes"

    # Get a list of all JSON theme files in the directory
    omp_themes=($(ls $omp_themes_dir/*.json))

    # Get the number of JSON theme files
    num_files=''${#omp_themes[@]}

    # Generate a random index
    random_index=$((RANDOM % num_files))

    # Select a random theme
    random_omp_theme=''${omp_themes[$random_index]}

    # Initialize oh-my-posh with the random theme
    eval "$(oh-my-posh init zsh --config $random_omp_theme)"
  '';
in {
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
    promptInit = builtins.readFile promptInitScript;
  };
}
