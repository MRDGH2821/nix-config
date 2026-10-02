# Session env + PATH. XDG base dirs are set by Home Manager itself; do not
# re-export them. SELINUX_MODE / antidot / mise-shim PATH from the chezmoi
# 00-export_paths.sh are intentionally dropped (declarative env; mise shims
# come from programs.mise's zsh integration).
#
# EDITOR/VISUAL are set by the zed module (zed.nix), not here.
{config, ...}: {
  home = {
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/cargo/bin"
      "$HOME/.local/share/soar/bin"
    ];
    sessionVariables = {
      CARGO_HOME = "${config.home.homeDirectory}/.local/share/cargo";
      PAGER = "less";
    };
  };
}
