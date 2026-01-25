#!/bin/sh
# Usage: toggle-theme.sh [light|dark]

. "$HOME/.local/share/theme/colors.sh"
STATE_FILE="$HOME/.local/state/theme"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
CLAUDE_CONFIG="$HOME/.claude.json"
BTOP_CONFIG="$HOME/.config/btop/btop.conf"
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$BTOP_CONFIG")"

CURRENT="dark"
[ -f "$STATE_FILE" ] && CURRENT=$(cat "$STATE_FILE")

if [ "$1" = "light" ] || [ "$1" = "dark" ]; then
  TARGET="$1"
elif [ "$CURRENT" = "dark" ]; then
  TARGET="light"
else
  TARGET="dark"
fi

[ "$CURRENT" = "$TARGET" ] && exit 0

if [ "$TARGET" = "light" ]; then
  echo "light" > "$STATE_FILE"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
  if [ -f "$VSCODE_SETTINGS" ]; then
    tmp=$(mktemp) && jq '
      ."workbench.colorTheme" = "Paper" |
      ."workbench.preferredDarkColorTheme" = "Paper" |
      ."workbench.preferredLightColorTheme" = "Paper"
    ' "$VSCODE_SETTINGS" > "$tmp" && mv "$tmp" "$VSCODE_SETTINGS"
  fi
  if [ -f "$CLAUDE_CONFIG" ]; then
    tmp=$(mktemp) && jq '.theme = "light"' "$CLAUDE_CONFIG" > "$tmp" && mv "$tmp" "$CLAUDE_CONFIG"
  else
    echo '{"theme": "light"}' > "$CLAUDE_CONFIG"
  fi
  pkill -USR2 foot
  ~/.local/bin/sway-theme.sh
  if [ -f "$BTOP_CONFIG" ]; then
    sed -i 's/^color_theme = .*/color_theme = "paper"/' "$BTOP_CONFIG"
  else
    echo 'color_theme = "paper"' > "$BTOP_CONFIG"
  fi
  tmux set -g pane-border-style "fg=$PAPER_BORDER_INACTIVE" 2>/dev/null
  tmux set -g pane-active-border-style "fg=$PAPER_BORDER" 2>/dev/null
  AERC_PANE=$(tmux list-windows -a -F '#{window_name} #{pane_id}' 2>/dev/null | grep -m1 '^aerc ' | cut -d' ' -f2)
  [ -n "$AERC_PANE" ] && tmux send-keys -t "$AERC_PANE" ':reload -s paper' Enter
  tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -E ' (nvim|vim)$' | cut -d' ' -f1 | while read pane; do
    tmux send-keys -t "$pane" Escape ':lua require("config.theme").apply()' Enter
  done
else
  echo "dark" > "$STATE_FILE"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  if [ -f "$VSCODE_SETTINGS" ]; then
    tmp=$(mktemp) && jq '
      ."workbench.colorTheme" = "Nord Deep" |
      ."workbench.preferredDarkColorTheme" = "Nord Deep" |
      ."workbench.preferredLightColorTheme" = "Nord Deep"
    ' "$VSCODE_SETTINGS" > "$tmp" && mv "$tmp" "$VSCODE_SETTINGS"
  fi
  if [ -f "$CLAUDE_CONFIG" ]; then
    tmp=$(mktemp) && jq '.theme = "dark"' "$CLAUDE_CONFIG" > "$tmp" && mv "$tmp" "$CLAUDE_CONFIG"
  else
    echo '{"theme": "dark"}' > "$CLAUDE_CONFIG"
  fi
  pkill -USR1 foot
  ~/.local/bin/sway-theme.sh
  if [ -f "$BTOP_CONFIG" ]; then
    sed -i 's/^color_theme = .*/color_theme = "nord"/' "$BTOP_CONFIG"
  else
    echo 'color_theme = "nord"' > "$BTOP_CONFIG"
  fi
  tmux set -g pane-border-style "fg=$NORD_FG_MUTED" 2>/dev/null
  tmux set -g pane-active-border-style "fg=$NORD_BORDER" 2>/dev/null
  AERC_PANE=$(tmux list-windows -a -F '#{window_name} #{pane_id}' 2>/dev/null | grep -m1 '^aerc ' | cut -d' ' -f2)
  [ -n "$AERC_PANE" ] && tmux send-keys -t "$AERC_PANE" ':reload -s nord' Enter
  tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep -E ' (nvim|vim)$' | cut -d' ' -f1 | while read pane; do
    tmux send-keys -t "$pane" Escape ':lua require("config.theme").apply()' Enter
  done
fi
