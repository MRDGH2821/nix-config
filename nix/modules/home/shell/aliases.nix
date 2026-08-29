# ls/ll/la/l come from programs.eza Zsh integration (do not re-add them here;
# eza's mkDefault aliases already cover them).
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
    tb = "nc termbin.com 9999";
    tf = "touchfile";
    vdir = "vdir --color=auto";
  };
}
