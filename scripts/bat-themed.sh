#!/bin/sh
STATE_FILE="$HOME/.local/state/theme"
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "light" ]; then
  exec bat --theme="PaperCustom" --style="numbers,changes" "$@"
else
  exec bat --theme="NordCustom" --style="numbers,changes" "$@"
fi
