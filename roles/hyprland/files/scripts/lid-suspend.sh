#!/bin/sh
# Lid-close suspend scheduler for the Hyprland lid switch binds.
#
#   close - schedule a suspend after SUSPEND_DELAY seconds with the lid closed
#   open  - cancel the scheduled suspend
#
# Implemented with transient systemd user timers so nothing has to keep
# running in the background: the timer and its service disappear once they
# fire or are stopped. The scheduled command re-checks the lid state, so a
# lid opened in the final seconds never puts a busy machine to sleep.

SUSPEND_DELAY="${LID_SUSPEND_SEC:-1800}"
UNIT="hypridle-lid-suspend"

# login1 is a system-bus service, so query it explicitly with --system:
# a systemd-run --user service defaults to the user bus, where it does not exist.
LID_CLOSED_CMD="busctl --system --quiet get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed"

case "$1" in
    close)
        systemctl --user stop "$UNIT.timer" 2>/dev/null || true
        systemd-run --user --unit="$UNIT" \
            --on-active="$SUSPEND_DELAY" \
            sh -c "$LID_CLOSED_CMD | grep -q true && systemctl suspend"
        ;;
    open)
        systemctl --user stop "$UNIT.timer" 2>/dev/null || true
        ;;
    *)
        printf 'usage: %s close|open\n' "$0" >&2
        exit 2
        ;;
esac
