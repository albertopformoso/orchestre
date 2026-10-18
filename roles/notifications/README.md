# Mako notifications

Mako's 0px corner radius and 1px border match the current Hyprland geometry.

## Notification sounds

Every arriving notification plays a sound via `paplay` (provided by `libpulse`).
The role installs PCM WAV files into `~/.local/share/sounds/orchestre/`.
The original Universfield MP3 downloads are kept in `files/sounds/source/`;
the WAV copies are bundled so deployment does not need FFmpeg or Downloads.

| Type | Urgency / color | Sound | Source |
| --- | --- | --- | --- |
| Normal | `low` / gray | `normal.wav` | `universfield-new-notification-059-494262.mp3` |
| Warning | `normal` / yellow | `warning.wav` | `universfield-new-notification-056-494256.mp3` |
| Error | `critical` / red | `error.wav` | `universfield-new-notification-035-485894.mp3` |
| Low battery | normal or critical | `dialog-warning.oga` | System `sound-theme-freedesktop` package |

Both low-battery levels use `/usr/share/sounds/freedesktop/stereo/dialog-warning.oga`.
The original cork-pop download is retained in `files/sounds/source/` as an unused option.

Most applications send normal urgency, which uses the yellow warning style.
The shared battery service marks its 30% and 15% discharging alerts with category
`device.battery.low`. This category overrides the urgency sound, so only the
battery sound plays; colors and timeouts still follow urgency. Battery-full
notifications keep the normal-urgency sound.

Run these individually in your desktop terminal (`notify-send` is from `libnotify`):

```sh
notify-send -u low 'Normal notification' 'Testing the normal sound'
notify-send -u normal 'Warning notification' 'Testing the warning sound'
notify-send -u critical 'Error notification' 'Testing the error sound'
notify-send -u normal -c device.battery.low 'Low battery' 'Testing the battery sound'
notify-send -u critical -c device.battery.low 'Very low battery' 'Testing the battery sound'
```

These simulate notifications without changing the battery state. Critical
notifications stay visible until dismissed (right-click). To test audio alone:

```sh
paplay "$HOME/.local/share/sounds/orchestre/normal.wav"
```

To regenerate a WAV after replacing a source file, from the repository root:

```sh
ffmpeg -i roles/notifications/files/sounds/source/universfield-new-notification-059-494262.mp3 \
  -map_metadata -1 -c:a pcm_s16le roles/notifications/files/sounds/normal.wav
```

## Shared battery alerts

`battery-notifications.service` starts with Hyprland and checks system batteries
every 15 seconds. Waybar only displays battery status; its per-monitor modules
do not send alerts. The service sends warning (30%), critical (15%), and full
(100% on external power) notifications. Starting below 15% sends only critical.

A session-wide lock prevents multiple instances. Alert state lives in
`$XDG_RUNTIME_DIR/battery-notifications/state.json`, surviving service and bar
restarts until logout. Full alerts rearm after the charge drops to 95% or below,
preventing repeated alerts from 99–100% fluctuations or briefly unplugging.
Low alerts rearm on external power or after recovery above 33% / 18%.
At a fresh login, a battery already in an alert state produces one notification.

After deployment into an existing session:

```sh
systemctl --user daemon-reload
systemctl --user start battery-notifications.service
pkill -USR2 -x waybar
```

Diagnostics: `journalctl --user -u battery-notifications.service`.
Regression checks: `python -B roles/notifications/tests/test_battery.py`.

## Workspace integration

`notification-workspaces.service` starts with Hyprland. It observes notification
calls and replies on the user D-Bus, correlates the returned ID with the sender,
and tracks windows through Hyprland's event socket. Notification text is neither
logged nor saved. The service requires `python-gobject` and Mako 1.11 or later.

- Left-click keeps Mako's default action and activation token. The helper also
  focuses an identified source window. Notifications without actions use the
  helper directly. Right-click dismisses.
- Sources are matched by process ancestry (including CLI tools inside terminals)
  or exact desktop identity / `StartupWMClass`. Multiple matching windows are
  intentionally unresolved. Browser tabs and multiplexed terminal sessions may
  require sender-specific metadata; an app's native action is retained.
- Attention blinks amber until the originating workspace is visited, even if
  the notification expires or is dismissed. New notifications on the focused
  workspace do not blink. Attention and clicks follow a moved window; closed
  windows are removed. Stable window IDs prevent address-reuse mistakes.
- Restarting the helper clears attention and routing history. Notifications
  already present before startup retain their native actions.

Waybar has no external setter for native workspace urgency. The helper writes
`~/.config/waybar/notification-attention.css`, imported with live CSS reload.
Its selectors follow the native module's per-output, ID-sorted button order.
Keep `all-outputs=false`, `show-special=true`, `ignore-workspaces=["^(special:)?magic$"]`,
and `sort-by=id`; the helper excludes `magic` from its button mapping too. Custom
persistent placeholders, additional filtering, or multiple workspace modules require
adapting this mapping. Native urgent workspaces also use amber; hardware-critical indicators
keep their separate red animation.

After deploying the roles into an existing session:

```sh
systemctl --user daemon-reload
systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user restart notification-workspaces.service
makoctl reload
pkill -USR2 -x waybar
```

Diagnostics: `journalctl --user -u notification-workspaces.service`.
Regression checks: `python -B roles/notifications/tests/test_workspaces.py`.
