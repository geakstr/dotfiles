{ lib, ... }:

let
  colors = import ../../modules/home/theme/colors.nix;
  # Foot config requires colors without # prefix
  strip = c: lib.removePrefix "#" c;
in
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "CaskaydiaCove Nerd Font Mono:size=11";
        line-height = "14";
        pad = "0x0";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      url = {
        launch = "xdg-open \${url}";
      };
      key-bindings = {
        scrollback-up-page = "none";
        scrollback-down-page = "none";
      };
      text-bindings = {
        "\\x0a" = "Shift+Return";
        "\\x00" = "Control+space";
      };
      # Dark theme (default, SIGUSR1)
      colors = {
        background = strip colors.nord.bgDark;
        foreground = strip colors.nord.fgDim;
        regular0 = strip colors.nord.bgAlt;
        regular1 = strip colors.nord.red;
        regular2 = strip colors.nord.green;
        regular3 = strip colors.nord.yellow;
        regular4 = strip colors.nord.blue;
        regular5 = strip colors.nord.magenta;
        regular6 = strip colors.nord.cyan;
        regular7 = strip colors.nord.fgBright;
        bright0 = strip colors.nord.fgMuted;
        bright1 = strip colors.nord.red;
        bright2 = strip colors.nord.green;
        bright3 = strip colors.nord.yellow;
        bright4 = strip colors.nord.blue;
        bright5 = strip colors.nord.magenta;
        bright6 = strip colors.nord.cyanBright;
        bright7 = strip colors.nord.fg;
      };
      # Light theme - Paper (SIGUSR2)
      colors2 = {
        background = strip colors.paper.bg;
        foreground = strip colors.paper.fg;
        regular0 = strip colors.paper.bg;
        regular1 = strip colors.paper.red;
        regular2 = strip colors.paper.green;
        regular3 = strip colors.paper.yellow;
        regular4 = strip colors.paper.blue;
        regular5 = strip colors.paper.magenta;
        regular6 = strip colors.paper.cyan;
        regular7 = strip colors.paper.fg;
        bright0 = strip colors.paper.fgMuted;
        bright1 = strip colors.paper.red;
        bright2 = strip colors.paper.green;
        bright3 = strip colors.paper.yellow;
        bright4 = strip colors.paper.blue;
        bright5 = strip colors.paper.magenta;
        bright6 = strip colors.paper.fgSubtle;
        bright7 = strip colors.paper.fg;
      };
    };
  };
}
