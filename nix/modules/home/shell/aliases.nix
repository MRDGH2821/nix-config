# ls / ll / la / l all come from the programs.eza Zsh integration, which aliases
# `ls` to `eza` (mkDefault). zsh expands aliases recursively, so `l` must NOT
# resolve to `ls <flag>` that eza rejects (e.g. `ls -CF` -> `eza -CF`, and eza
# has no `-C`). Re-add `l` directly in eza terms (grid is eza's default).
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
    l = "eza -F";
    tb = "nc termbin.com 9999";
    tf = "touchfile";
    vdir = "vdir --color=auto";
  };
}
