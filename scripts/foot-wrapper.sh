#!/bin/sh
# foot responds to SIGUSR1 (dark) / SIGUSR2 (light) for live theme switching
. "$HOME/.local/share/theme/colors.sh"
STATE_FILE="$HOME/.local/state/theme"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "light" ]; then
  (sleep 0.01 && pkill -USR2 foot) &
  exec foot tmux new-session \; set-option destroy-unattached on \; \
    set -g pane-border-style "fg=$PAPER_BORDER_INACTIVE" \; \
    set -g pane-active-border-style "fg=$PAPER_BORDER"
fi
exec foot tmux new-session \; set-option destroy-unattached on
