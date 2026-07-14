#!/bin/bash

# Define paths
capacity_file="/sys/class/power_supply/BAT1/capacity"
status_file="/sys/class/power_supply/BAT1/status"

# Check if battery exists
if [ ! -f "$capacity_file" ]; then
    echo "No Bat"
    exit 0
fi

# Read current capacity and status
capacity=$(cat "$capacity_file")
status=$(cat "$status_file")

# Determine icon based on status and percentage
if [ "$status" = "Charging" ]; then
    if [ "$capacity" -ge 80 ]; then
        icon="󰂄" # Charging icon (Nerd Font)
    elif [ "$capacity" -ge 60 ]; then
        icon="󰂉"
    elif [ "$capacity" -ge 40 ]; then
        icon="󰂈"
    elif [ "$capacity" -ge 20 ]; then
        icon="󰂆"
    else
        icon="󰢟"
    fi
elif [ "$capacity" -ge 80 ]; then
    icon=" " # Full
elif [ "$capacity" -ge 60 ]; then
    icon=" " # 3/4
elif [ "$capacity" -ge 40 ]; then
    icon=" " # Half
elif [ "$capacity" -ge 20 ]; then
    icon=" " # 1/4
else
    icon=" " # Empty
fi

# Output the formatted string for Hyprlock
echo "$icon $capacity%"