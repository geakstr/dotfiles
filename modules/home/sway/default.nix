{ pkgs, ... }:

let
  colors = import ../theme/colors.nix;
in
{
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      defaultWorkspace = "workspace number 1";

      fonts = {
        names = ["CaskaydiaCove Nerd Font"];
        size = 8.5;
      };

      output = {
        # Laptop display
        "eDP-1" = { scale = "2"; position = "5120 0"; };
      };

      input = {
        "type:keyboard" = {
          xkb_layout = "us,ru";
          xkb_options = "caps:none";
          repeat_delay = "175";
          repeat_rate = "40";
        };
        "type:tablet_tool" = {
          events = "disabled";
        };
      };

      gaps = {
        inner = 1;
      };

      seat = {
        "*" = {
          xcursor_theme = "Adwaita 20";
        };
      };

      window = {
        border = 1;
      };

      colors = {
        focused = {
          border = colors.nord.border;
          background = colors.nord.bg;
          text = colors.nord.fg;
          indicator = colors.nord.border;
          childBorder = colors.nord.border;
        };
        unfocused = {
          border = colors.nord.bg;
          background = colors.nord.bg;
          text = colors.nord.fgMuted;
          indicator = colors.nord.bg;
          childBorder = colors.nord.bg;
        };
        focusedInactive = {
          border = colors.nord.bgAlt;
          background = colors.nord.bg;
          text = colors.nord.fgMuted;
          indicator = colors.nord.bgAlt;
          childBorder = colors.nord.bgAlt;
        };
        urgent = {
          border = colors.nord.urgent;
          background = colors.nord.bg;
          text = colors.nord.fg;
          indicator = colors.nord.urgent;
          childBorder = colors.nord.urgent;
        };
      };

      focus = {
        followMouse = false;
      };

      keybindings = let
        mod = "Mod1";
      in {
        "--to-code Mod1+q" = "kill";
        "--to-code Mod1+Return" = "exec ~/.local/bin/foot-wrapper";
        "--to-code Mod1+Shift+t" = "exec ~/.local/bin/toggle-theme.sh";
        "--to-code Mod1+Shift+s" = ''exec grim -g "$(slurp)" - | wl-copy && notify-send -t 5000 "Screenshot copied to clipboard"'';
        "--to-code Mod1+Escape" = "exec swaylock -f";

        "--to-code ${mod}+h" = "focus left";
        "--to-code ${mod}+j" = "focus down";
        "--to-code ${mod}+k" = "focus up";
        "--to-code ${mod}+l" = "focus right";
        "--to-code ${mod}+Left" = "focus left";
        "--to-code ${mod}+Down" = "focus down";
        "--to-code ${mod}+Up" = "focus up";
        "--to-code ${mod}+Right" = "focus right";

        "--to-code ${mod}+Shift+h" = "move left";
        "--to-code ${mod}+Shift+j" = "move down";
        "--to-code ${mod}+Shift+k" = "move up";
        "--to-code ${mod}+Shift+l" = "move right";
        "--to-code ${mod}+Shift+Left" = "move left";
        "--to-code ${mod}+Shift+Down" = "move down";
        "--to-code ${mod}+Shift+Up" = "move up";
        "--to-code ${mod}+Shift+Right" = "move right";

        "--to-code ${mod}+1" = "workspace number 1";
        "--to-code ${mod}+2" = "workspace number 2";
        "--to-code ${mod}+3" = "workspace number 3";
        "--to-code ${mod}+4" = "workspace number 4";
        "--to-code ${mod}+5" = "workspace number 5";
        "--to-code ${mod}+6" = "workspace number 6";
        "--to-code ${mod}+7" = "workspace number 7";
        "--to-code ${mod}+8" = "workspace number 8";
        "--to-code ${mod}+9" = "workspace number 9";
        "--to-code ${mod}+0" = "workspace number 10";

        "--to-code ${mod}+Shift+1" = "move container to workspace number 1";
        "--to-code ${mod}+Shift+2" = "move container to workspace number 2";
        "--to-code ${mod}+Shift+3" = "move container to workspace number 3";
        "--to-code ${mod}+Shift+4" = "move container to workspace number 4";
        "--to-code ${mod}+Shift+5" = "move container to workspace number 5";
        "--to-code ${mod}+Shift+6" = "move container to workspace number 6";
        "--to-code ${mod}+Shift+7" = "move container to workspace number 7";
        "--to-code ${mod}+Shift+8" = "move container to workspace number 8";
        "--to-code ${mod}+Shift+9" = "move container to workspace number 9";
        "--to-code ${mod}+Shift+0" = "move container to workspace number 10";

        "--to-code ${mod}+b" = "splith";
        "--to-code ${mod}+v" = "splitv";
        "--to-code ${mod}+s" = "layout stacking";
        "--to-code ${mod}+w" = "layout tabbed";
        "--to-code ${mod}+e" = "layout toggle split";
        "--to-code ${mod}+f" = "fullscreen";

        "--to-code Alt+Shift+space" = "floating toggle";
        "--to-code Ctrl+Alt+Shift+space" = "focus mode_toggle";

        "--to-code ${mod}+a" = "focus parent";
        "--to-code ${mod}+Shift+a" = "focus child";

        "--to-code ${mod}+r" = "mode resize";

        "--to-code ${mod}+Shift+minus" = "move scratchpad";
        "--to-code ${mod}+minus" = "scratchpad show";

        "--to-code ${mod}+Shift+c" = "reload";
        "--to-code ${mod}+Shift+e" = "exec swaymsg exit";

        "XF86AudioMute" = "exec ~/.local/bin/volume-notify.sh mute";
        "XF86AudioLowerVolume" = "exec ~/.local/bin/volume-notify.sh down";
        "XF86AudioRaiseVolume" = "exec ~/.local/bin/volume-notify.sh up";

        "XF86MonBrightnessDown" = "exec ~/.local/bin/brightness-notify.rs down";
        "XF86MonBrightnessUp" = "exec ~/.local/bin/brightness-notify.rs up";
      };

      modes = {
        resize = {
          "--to-code h" = "resize shrink width 10 px";
          "--to-code j" = "resize grow height 10 px";
          "--to-code k" = "resize shrink height 10 px";
          "--to-code l" = "resize grow width 10 px";
          "--to-code Left" = "resize shrink width 10 px";
          "--to-code Down" = "resize grow height 10 px";
          "--to-code Up" = "resize shrink height 10 px";
          "--to-code Right" = "resize grow width 10 px";
          "--to-code Return" = "mode default";
          "--to-code Escape" = "mode default";
        };
      };

      bars = [];
    };

    extraConfig = ''
      bindswitch --reload --locked lid:off output eDP-1 enable
      bindswitch --reload --locked lid:on output eDP-1 disable
      default_border pixel 1
      include /etc/sway/config.d/*
      exec ~/.local/bin/sway-displays.sh --daemon
      exec opensnitch-ui
      exec ~/.local/bin/sway-theme.sh
    '';
  };
}
