#!/bin/sh
# Toggle helper for hypridle screen-off power management.
#
#   save    - record the active powerprofilesctl profile and switch to power-saver
#   restore - switch back to the recorded profile and clear the record
#
# The record lives in XDG_RUNTIME_DIR so it is per-session and cleared on logout.
# While already in "idle" mode, save keeps the originally recorded profile so
# repeated timeouts never overwrite the user's real value with "power-saver".

STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypridle-ppd-profile"

case "$1" in
    save)
        [ -f "$STATE_FILE" ] && exit 0
        CURRENT="$(powerprofilesctl get 2>/dev/null)" || exit 0
        case "$CURRENT" in
            power-saver|balanced|performance)
                printf '%s\n' "$CURRENT" > "$STATE_FILE"
                powerprofilesctl set power-saver
                ;;
        esac
        ;;
    restore)
        [ -f "$STATE_FILE" ] || exit 0
        SAVED="$(cat "$STATE_FILE")"
        rm -f "$STATE_FILE"
        [ -n "$SAVED" ] && powerprofilesctl set "$SAVED"
        ;;
    *)
        printf 'usage: %s save|restore\n' "$0" >&2
        exit 2
        ;;
esac
