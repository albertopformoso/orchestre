#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/kbd_backlight"
BRIGHTNESS="/sys/class/leds/msiacpi::kbd_backlight/brightness"

case "$1" in
  off)
    cat "$BRIGHTNESS" > "$STATE_FILE"
    echo 0 | sudo tee "$BRIGHTNESS" >/dev/null
    ;;
  restore)
    if [[ -f "$STATE_FILE" ]]; then
      level=$(cat "$STATE_FILE")
    else
      level=3
    fi
    echo "$level" | sudo tee "$BRIGHTNESS" >/dev/null
    ;;
esac
