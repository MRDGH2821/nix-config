{
  pkgs,
  config,
  ...
}: let
  zimrcContent = ''
    # Start configuration added by Zim install {{{
    #
    # This is not sourced during shell startup, and it's only used to configure the
    # zimfw plugin manager.
    #

    #
    # Modules
    #

    # Sets sane Zsh built-in environment options.
    zmodule environment
    # Provides handy git aliases and functions.
    zmodule git
    # Applies correct bindkeys for input events.
    zmodule input
    # Sets a custom terminal title.
    zmodule termtitle
    # Utility aliases and functions. Adds colour to ls, grep and less.
    zmodule utility

    zmodule fzf

    zmodule ssh

    zmodule exa

    zmodule joke/zim-chezmoi

    zmodule kiesman99/zim-zoxide

    zmodule magic-enter

    #
    # Plugins from oh-my-zsh
    #

    zmodule ohmyzsh/ohmyzsh --root plugins/alias-finder

    zmodule ohmyzsh/ohmyzsh --root plugins/common-aliases

    zmodule ohmyzsh/ohmyzsh --root plugins/command-not-found

    zmodule ohmyzsh/ohmyzsh --root plugins/docker

    zmodule ohmyzsh/ohmyzsh --root plugins/docker-compose

    zmodule ohmyzsh/ohmyzsh --root plugins/fnm

    zmodule ohmyzsh/ohmyzsh --root plugins/gh

    zmodule ohmyzsh/ohmyzsh --root plugins/systemd

    zmodule ohmyzsh/ohmyzsh --root plugins/tldr

    zmodule ohmyzsh/ohmyzsh --root plugins/vscode

    #
    # Prompt
    #

    # Exposes to prompts how long the last command took to execute, used by asciiship.
    zmodule duration-info
    # Exposes git repository status information to prompts, used by asciiship.
    zmodule git-info
    # A heavily reduced, ASCII-only version of the Spaceship and Starship prompts.
    zmodule asciiship

    #
    # Completion
    #

    # Additional completion definitions for Zsh.
    zmodule zsh-users/zsh-completions --fpath src
    # Enables and configures smart and extensive tab completion.
    # completion must be sourced after all modules that add completion definitions.
    zmodule completion

    #
    # Modules that must be initialized last
    #

    # Fish-like syntax highlighting for Zsh.
    # zsh-users/zsh-syntax-highlighting must be sourced after completion
    zmodule zsh-users/zsh-syntax-highlighting
    # Fish-like history search (up arrow) for Zsh.
    # zsh-users/zsh-history-substring-search must be sourced after zsh-users/zsh-syntax-highlighting
    zmodule zsh-users/zsh-history-substring-search
    # Fish-like autosuggestions for Zsh.
    zmodule zsh-users/zsh-autosuggestions
    # }}} End configuration added by Zim install
  '';

  # Get all regular users (non-system users)
  regularUsers =
    builtins.filter
    (name: config.users.users.${name}.isNormalUser)
    (builtins.attrNames config.users.users);

  # Create tmpfiles rules for each user
  mkZimrcRule = username: let
    user = config.users.users.${username};
    home = user.home;
  in "f+ ${home}/.zimrc 0644 ${username} ${user.group} - ${zimrcContent}";
in {
  systemd.tmpfiles.rules = map mkZimrcRule regularUsers;

  programs.zsh = {
    loginShellInit = ''
      ZIM_HOME=''${ZDOTDIR:-$HOME}/.zim
      if [[ ! ''${ZIM_HOME}/init.zsh -nt ''${ZIM_CONFIG_FILE:-''${ZDOTDIR:-''${HOME}}/.zimrc} ]]; then
        source ${pkgs.zimfw}/zimfw.zsh init
      fi
      source ''${ZIM_HOME}/init.zsh
    '';
  };
}
