#!/bin/sh
STATE_FILE="$HOME/.local/state/theme"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "light" ]; then
  exec delta --syntax-theme="PaperCustom" --light "$@"
else
  exec delta --syntax-theme="NordCustom" "$@"
fi
