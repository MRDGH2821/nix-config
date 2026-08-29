# ls / ll / la come from the programs.eza Zsh integration (mkDefault aliases);
# only `l` is not provided by eza, so it is re-added below.
{
  home.shellAliases = {
    # from chezmoi shell_aliases.sh (dnf=dnf5 and zed=zeditor intentionally
    # dropped: Fedora-only / handled via programs.zed-editor + PATH).
    bunx = "bun x";
    cat = "bat --paging=never";
    dir = "dir --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
    grep = "grep --color=auto";
    l = "ls -CF";
    tb = "nc termbin.com 9999";
    tf = "touchfile";
    vdir = "vdir --color=auto";
  };
}
