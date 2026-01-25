#!/bin/sh
focused=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .app_id // .window_properties.class // empty')
if [ "$focused" = "foot" ]; then
  tmux kill-window
else
  swaymsg kill
fi
