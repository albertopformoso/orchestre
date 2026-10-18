#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: setavatar <path-to-image>" >&2
    exit 1
fi

IMAGE_PATH=$(realpath -e -- "$1")
if [ ! -f "$IMAGE_PATH" ] || [ ! -r "$IMAGE_PATH" ]; then
    echo "Avatar must be a readable image file: $IMAGE_PATH" >&2
    exit 1
fi

SDDM_HELPER=/usr/local/libexec/orchestre-sddm-avatar
if [ ! -x "$SDDM_HELPER" ]; then
    echo "SDDM avatar helper is missing; deploy the sddm role first." >&2
    exit 1
fi

# Keep the original resolution; PNG conversion is lossless after decoding.
TEMP_IMAGE=$(mktemp --suffix=.png)
trap 'rm -f -- "$TEMP_IMAGE"' EXIT
/usr/bin/python3 - "$IMAGE_PATH" "$TEMP_IMAGE" <<'PY'
import sys
import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, GLib

try:
    image = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1]).apply_embedded_orientation()
    image.savev(sys.argv[2], "png", [], [])
except GLib.Error as error:
    sys.exit(f"Invalid avatar: {error.message}")
PY

sudo -n -- "$SDDM_HELPER" < "$TEMP_IMAGE"
echo "SDDM avatar updated to: $IMAGE_PATH (visible next time the greeter opens)"
