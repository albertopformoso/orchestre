#!/bin/bash

# Check if an image path was provided
if [ -z "$1" ]; then
    echo "Usage: setbg <path-to-wallpaper>"
    exit 1
fi

# Get the absolute path of the provided image
# (This is important because symlinks break if given relative paths)
IMAGE_PATH=$(realpath "$1")

# Single common symlink — source of truth for hyprlock, awww, and autostart
WALLPAPER_LINK="$HOME/.config/hypr/current_wallpaper"

# The path to your hyprlock symlink
HYPRLOCK_SYMLINK="$HOME/.config/hypr/hyprlock/wallpaper"

# 1. Force-create/update the symlink (-s makes it symbolic, -f forces overwrite)
ln -sf "$IMAGE_PATH" "$WALLPAPER_LINK"
ln -sf "$IMAGE_PATH" "$HYPRLOCK_SYMLINK"

# 2. Set the desktop wallpaper
awww img "$IMAGE_PATH" --transition-type wipe

echo "Wallpaper and hyprlock background updated to: $IMAGE_PATH"
