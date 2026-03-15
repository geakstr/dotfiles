#!/usr/bin/env bash
# Configure displays - handles Samsung ultrawide in single and PBP modes
# Usage: sway-displays.sh [--daemon]

configure_displays() {
  # Disable laptop display if lid is closed
  lid_state=$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null | awk '{print $2}')
  if [ "$lid_state" = "closed" ]; then
    swaymsg output eDP-1 disable
  fi

  outputs=$(swaymsg -t get_outputs -r)

  # Only count Samsung Odyssey DP outputs (ignore internal DP like Synaptics mux)
  dp_outputs=$(echo "$outputs" | jq -r '.[] | select(.make == "Samsung Electric Company" and .model == "Odyssey G91F") | select(.name | startswith("DP")) | .name')
  dp_count=$(echo "$dp_outputs" | grep -c . || echo 0)

  if [ "$dp_count" -ge 2 ]; then
    # PBP mode: detect this machine's portion by available modes
    # Possible widths: 1/3=1680, 1/2=2560, 2/3=3440
    for dp in $dp_outputs; do
      # Get the best available PBP mode for this output (prefer larger)
      mode=$(echo "$outputs" | jq -r --arg name "$dp" '
        .[] | select(.name == $name) | .modes[] |
        select(.width == 3440 or .width == 2560 or .width == 1680) |
        "\(.width)x\(.height)"
      ' | sort -t'x' -k1 -nr | head -1)

      if [ -n "$mode" ]; then
        current_mode=$(echo "$outputs" | jq -r --arg name "$dp" '.[] | select(.name == $name) | "\(.current_mode.width)x\(.current_mode.height)"')
        [ "$current_mode" != "$mode" ] && swaymsg output "$dp" mode "$mode" position 0 0 scale 1
      else
        # No valid PBP mode - this is the other machine's portion
        swaymsg output "$dp" disable
      fi
    done
  elif [ "$dp_count" -eq 1 ]; then
    # Single DP output - could be single mode or PBP with only our portion connected
    dp=$(echo "$dp_outputs" | head -1)

    # Check if 5120 mode available (single mode) or use best PBP mode
    has_5120=$(echo "$outputs" | jq -r --arg name "$dp" '
      .[] | select(.name == $name) | .modes[] | select(.width == 5120) | .width
    ' | head -1)

    if [ "$has_5120" = "5120" ]; then
      current_w=$(echo "$outputs" | jq -r --arg name "$dp" '.[] | select(.name == $name) | .current_mode.width')
      [ "$current_w" != "5120" ] && swaymsg output "$dp" mode 5120x1440 position 0 0 scale 1
    else
      # PBP mode with single connection
      mode=$(echo "$outputs" | jq -r --arg name "$dp" '
        .[] | select(.name == $name) | .modes[] |
        select(.width == 3440 or .width == 2560 or .width == 1680) |
        "\(.width)x\(.height)"
      ' | sort -t'x' -k1 -nr | head -1)
      if [ -n "$mode" ]; then
        current_mode=$(echo "$outputs" | jq -r --arg name "$dp" '.[] | select(.name == $name) | "\(.current_mode.width)x\(.current_mode.height)"')
        [ "$current_mode" != "$mode" ] && swaymsg output "$dp" mode "$mode" position 0 0 scale 1
      fi
    fi
  fi

  # Handle HDMI (eGPU) - prefer over DP if both connected in single mode
  hdmi=$(echo "$outputs" | jq -r '.[] | select(.make == "Samsung Electric Company" and .model == "Odyssey G91F") | select(.name | startswith("HDMI")) | .name' | head -1)
  if [ -n "$hdmi" ]; then
    has_5120=$(echo "$outputs" | jq -r --arg name "$hdmi" '
      .[] | select(.name == $name) | .modes[] | select(.width == 5120) | .width
    ' | head -1)

    if [ "$has_5120" = "5120" ]; then
      # HDMI in single mode - disable DP duplicate if exists
      dp=$(echo "$outputs" | jq -r '.[] | select(.make == "Samsung Electric Company" and .model == "Odyssey G91F") | select(.name | startswith("DP")) | .name' | head -1)
      [ -n "$dp" ] && swaymsg output "$dp" disable
      current_w=$(echo "$outputs" | jq -r --arg name "$hdmi" '.[] | select(.name == $name) | .current_mode.width')
      [ "$current_w" != "5120" ] && swaymsg output "$hdmi" mode 5120x1440 position 0 0 scale 1
    fi
  fi
}

run_daemon() {
  echo "sway-displays: starting daemon"

  # Configure on startup
  configure_displays

  # Subscribe to output events and reconfigure on changes
  swaymsg -m -t subscribe '["output"]' | while read -r event; do
    # Debounce: wait for rapid events to settle
    sleep 0.5

    # Drain any queued events
    while read -r -t 0.1 _; do :; done

    echo "sway-displays: output change detected, reconfiguring"
    configure_displays
  done
}

case "${1:-}" in
  --daemon)
    run_daemon
    ;;
  *)
    configure_displays
    ;;
esac
