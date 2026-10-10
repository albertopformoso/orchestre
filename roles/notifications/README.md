# Mako notifications

Mako's 0px corner radius and 1px border match the current Hyprland geometry.

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
