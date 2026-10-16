# SDDM

Subtle dark glass panels sit over a full-screen blurred wallpaper during login.
Panels and popups use 3px corners, with circular avatars, a pill-shaped password
field, and a circular arrow button for sign-in. Power icons have transparent
backgrounds and turn from gray to white on hover or keyboard focus. The existing
font settings are preserved.

## Deploy just SDDM and setbg

From the repository root on an already-provisioned machine:

```sh
ansible-playbook site.yml --tags sddm --ask-become-pass
```

This installs the theme and wallpaper helper and updates `setbg`. It does not
restart a running SDDM service. The initial wallpaper comes from
`~/.config/hypr/current_wallpaper` when available. Later deployments preserve the
saved wallpaper.

## Preview without logging out

Preview the repository theme:

```sh
sddm-greeter-qt6 --test-mode --theme "$PWD/roles/sddm/files"
```

Or preview the installed theme:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/orchestre
```

Run as your normal user. Close the preview window to exit. Test mode uses sample
users and sessions. On distributions that name the Qt 6 greeter `sddm-greeter`,
use that binary instead.

## Wallpaper synchronization

```sh
setbg "/path/to/wallpaper.jpg"
```

`setbg` validates and converts the image using GdkPixbuf as the desktop user,
then streams the PNG to a root-owned helper. A narrowly scoped sudo rule allows
that helper with no arguments. It atomically publishes only
`/var/lib/orchestre/sddm/background.png`, readable before login, independently of
home-directory permissions. The desktop and Hyprlock retain their original-image
symlinks. SDDM shows the new image the next time the greeter opens.

Python GObject bindings and GdkPixbuf are installed by the system role. If no
synchronized image is available, the theme falls back to its bundled wallpaper.
