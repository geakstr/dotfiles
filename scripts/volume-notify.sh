#!/bin/sh
case "$1" in
  up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac

vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
pct=$(echo "$vol" | awk '{printf "%.0f%%", $2*100}')
if echo "$vol" | grep -q MUTED; then
  msg="Volume: Muted ($pct)"
else
  msg="Volume: $pct"
fi
notify-send -h string:x-canonical-private-synchronous:volume -t 1500 "$msg"
