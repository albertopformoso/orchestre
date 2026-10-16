#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: setbg <path-to-wallpaper>" >&2
    exit 1
fi

IMAGE_PATH=$(realpath -e -- "$1")
if [ ! -f "$IMAGE_PATH" ] || [ ! -r "$IMAGE_PATH" ]; then
    echo "Wallpaper must be a readable image file: $IMAGE_PATH" >&2
    exit 1
fi

SDDM_HELPER=/usr/local/libexec/orchestre-sddm-background
if [ ! -x "$SDDM_HELPER" ]; then
    echo "SDDM wallpaper helper is missing; deploy the sddm role first." >&2
    exit 1
fi

# Validate and normalize as the desktop user. SDDM always gets a PNG, regardless
# of the original format, without requiring access to the user's home at boot.
TEMP_IMAGE=$(mktemp --suffix=.png)
trap 'rm -f -- "$TEMP_IMAGE"' EXIT
/usr/bin/python3 - "$IMAGE_PATH" "$TEMP_IMAGE" <<'PY'
import sys
import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, GLib

try:
    image = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
    image.savev(sys.argv[2], "png", [], [])
except GLib.Error as error:
    sys.exit(f"Invalid wallpaper: {error.message}")
PY

# The privileged helper only accepts stdin and writes one fixed destination.
sudo -n -- "$SDDM_HELPER" < "$TEMP_IMAGE"

WALLPAPER_LINK="$HOME/.config/hypr/current_wallpaper"
HYPRLOCK_SYMLINK="$HOME/.config/hypr/hyprlock/wallpaper"
mkdir -p -- "$(dirname "$HYPRLOCK_SYMLINK")"
ln -sfnT -- "$IMAGE_PATH" "$WALLPAPER_LINK"
ln -sfnT -- "$IMAGE_PATH" "$HYPRLOCK_SYMLINK"

if ! awww img "$IMAGE_PATH" --transition-type wipe; then
    echo "Wallpaper saved for SDDM, Hyprlock, and next session; awww could not update the running desktop." >&2
    exit 1
fi

echo "Desktop, Hyprlock, and SDDM background updated to: $IMAGE_PATH"
