#!/bin/sh
. "$HOME/.local/share/theme/colors.sh"
STATE_FILE="$HOME/.local/state/theme"
THEME="dark"
[ -f "$STATE_FILE" ] && THEME=$(cat "$STATE_FILE")

if [ "$THEME" = "light" ]; then
  swaymsg "client.focused $PAPER_BORDER $PAPER_BG $PAPER_FG $PAPER_BORDER $PAPER_BORDER"
  swaymsg "client.unfocused $PAPER_BORDER_INACTIVE $PAPER_BG_HOVER $PAPER_FG_MUTED $PAPER_BORDER_INACTIVE $PAPER_BORDER_INACTIVE"
  swaymsg "client.focused_inactive $PAPER_BORDER_SUBTLE $PAPER_BG_HIGHLIGHT $PAPER_FG_MUTED $PAPER_BORDER_SUBTLE $PAPER_BORDER_SUBTLE"
  swaymsg "client.urgent $PAPER_URGENT $PAPER_BG $PAPER_FG $PAPER_URGENT $PAPER_URGENT"
else
  swaymsg "client.focused $NORD_BORDER $NORD_BG $NORD_FG $NORD_BORDER $NORD_BORDER"
  swaymsg "client.unfocused $NORD_BG $NORD_BG $NORD_FG_MUTED $NORD_BG $NORD_BG"
  swaymsg "client.focused_inactive $NORD_BG_ALT $NORD_BG $NORD_FG_MUTED $NORD_BG_ALT $NORD_BG_ALT"
  swaymsg "client.urgent $NORD_URGENT $NORD_BG $NORD_FG $NORD_URGENT $NORD_URGENT"
fi
