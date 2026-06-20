{
  inputs,
  pkgs,
  ...
}: let
  hypr-pkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hypr-plugins = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
in {
  wayland.windowManager.hyprland = {
    enable = true;
    # set the flake package
    package = hypr-pkgs.hyprland;
    portalPackage = hypr-pkgs.xdg-desktop-portal-hyprland;
    plugins = [
      hypr-plugins.hyprbars
    ];
    configType = "lua";
    systemd.variables = ["--all"];
    settings = {
      monitor = ",preferred,auto,1";
      "exec-once" = "waybar";
      input = {
        kb_layout = "us";
        follow_mouse = 1;
      };
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffff) rgba(00ff99ff) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
      "$mainMod" = "SUPER";
      bind =
        [
          "$mainMod, RETURN, exec, kitty"
          "$mainMod, Q, killactive"
          "$mainMod, M, exit"
          "$mainMod, F, togglefloating"
          "$mainMod, R, exec, rofi -show drun -show-icons"

          # Vim-style focus
          "$mainMod, h, movefocus, l"
          "$mainMod, l, movefocus, r"
          "$mainMod, k, movefocus, u"
          "$mainMod, j, movefocus, d"
        ]
        ++ (builtins.genList
          (
            x: let
              ws = toString (x + 1);
            in "$mainMod, ${ws}, workspace, ${ws}"
          )
          3)
        ++ (builtins.genList
          (
            x: let
              ws = toString (x + 1);
            in "$mainMod SHIFT, ${ws}, movetoworkspace, ${ws}"
          )
          3);
    };
  };
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-right = [
          "cpu"
          "memory"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
        };
        "clock" = {
          format = " {:%H:%M   %Y-%m-%d}";
        };
        "cpu" = {
          format = " {usage}%";
        };
        "memory" = {
          format = " {percentage}%";
        };
      };
    };

    style = ''
      * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 13px;
      }

      window#waybar {
          background: rgba(43, 48, 59, 0.85);
          color: #ffffff;
      }

      #workspaces button {
          padding: 0 5px;
          color: #ffffff;
      }

      #workspaces button.active {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
      }

      #clock, #cpu, #memory {
          padding: 0 10px;
          color: #ffffff;
      }
    '';
  };
}
