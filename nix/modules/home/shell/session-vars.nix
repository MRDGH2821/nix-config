# Session env + PATH. XDG base dirs are set by Home Manager itself; do not
# re-export them. SELINUX_MODE / antidot / mise-shim PATH from the chezmoi
# 00-export_paths.sh are intentionally dropped (declarative env; mise shims
# come from programs.mise's zsh integration).
#
# EDITOR/VISUAL point at Zed only on GUI (desktop) hosts, where Zed is present
# (OS-provided on fw16). On the headless NixOS servers (mine.gui.enable = false)
# they are left unset so the NixOS default (nano) wins instead of a missing
# `zed` binary breaking `git commit`, `systemctl edit`, etc.
{
  config,
  lib,
  ...
}: {
  home = {
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/cargo/bin"
      "$HOME/.local/share/soar/bin"
    ];
    sessionVariables =
      {
        CARGO_HOME = "${config.home.homeDirectory}/.local/share/cargo";
        PAGER = "less";
      }
      // lib.optionalAttrs config.mine.gui.enable {
        EDITOR = "zed --wait";
        VISUAL = "zed --wait";
      };
  };
}
