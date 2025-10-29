{
  environment.shellAliases = {
    cat = "bat --paging=never";
    dir = "dir --color=auto";
    egrep = "egrep --color=auto";
    fgrep = "fgrep --color=auto";
    grep = "grep --color=auto";
    l = "ls -CF";
    la = "ls -A";
    ll = "ls -alF";
    ls = "ls --color=auto";
    tb = "nc termbin.com 9999";
    vdir = "vdir --color=auto";
    tf = ''touchfile() { mkdir -p "$(dirname "$1")" && touch "$1" && echo "$1" }'';
  };
}
