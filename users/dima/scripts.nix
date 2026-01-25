{ pkgs, lib, ... }:

let
  colors = import ../../modules/home/theme/colors.nix;
in
{
  home.file = {
    # Generated from colors.nix - must stay in Nix for interpolation
    ".local/share/theme/colors.sh" = {
      text = ''
        # Nord (dark)
        NORD_BG="${colors.nord.bg}"
        NORD_BG_ALT="${colors.nord.bgAlt}"
        NORD_BG_HIGHLIGHT="${colors.nord.bgHighlight}"
        NORD_FG="${colors.nord.fg}"
        NORD_FG_DIM="${colors.nord.fgDim}"
        NORD_FG_MUTED="${colors.nord.fgMuted}"
        NORD_BORDER="${colors.nord.border}"
        NORD_BORDER_INACTIVE="${colors.nord.borderInactive}"
        NORD_URGENT="${colors.nord.urgent}"

        # Paper (light)
        PAPER_BG="${colors.paper.bg}"
        PAPER_BG_ALT="${colors.paper.bgAlt}"
        PAPER_BG_HIGHLIGHT="${colors.paper.bgHighlight}"
        PAPER_BG_HOVER="${colors.paper.bgHover}"
        PAPER_BG_ACTIVE="${colors.paper.bgActive}"
        PAPER_FG="${colors.paper.fg}"
        PAPER_FG_DIM="${colors.paper.fgDim}"
        PAPER_FG_MUTED="${colors.paper.fgMuted}"
        PAPER_BORDER="${colors.paper.border}"
        PAPER_BORDER_INACTIVE="${colors.paper.borderInactive}"
        PAPER_BORDER_SUBTLE="${colors.paper.borderSubtle}"
        PAPER_URGENT="${colors.paper.urgent}"
      '';
    };

    # External scripts from scripts/ directory
    # Benefits: proper syntax highlighting, independent testing, no Nix escaping
    ".local/bin/delta-themed" = {
      executable = true;
      source = ../../scripts/delta-themed.sh;
    };

    ".local/bin/bat-themed" = {
      executable = true;
      source = ../../scripts/bat-themed.sh;
    };

    ".config/bat/themes/NordCustom.tmTheme".source = ../../config/bat/NordCustom.tmTheme;
    ".config/bat/themes/PaperCustom.tmTheme".source = ../../config/bat/PaperCustom.tmTheme;

    ".local/bin/smart-kill" = {
      executable = true;
      source = ../../scripts/smart-kill.sh;
    };

    ".local/bin/foot-wrapper" = {
      executable = true;
      source = ../../scripts/foot-wrapper.sh;
    };

    ".local/bin/brightness-notify.rs" = {
      executable = true;
      source = ../../scripts/brightness-notify.rs;
    };

    ".local/bin/volume-notify.sh" = {
      executable = true;
      source = ../../scripts/volume-notify.sh;
    };

    ".local/bin/sway-theme.sh" = {
      executable = true;
      source = ../../scripts/sway-theme.sh;
    };

    ".local/bin/toggle-theme.sh" = {
      executable = true;
      source = ../../scripts/toggle-theme.sh;
    };
  };
}
