# Local Waybar fix

This package pins the previously deployed Waybar commit `6d60c8e0` and adds
`close-pending-window.patch`. It removes a closing window from the pending
creation queue, preventing short-lived dialogs from being inserted after closing.
The captured reproducer was a `zenity` dialog opened by Lutris that lived about
one millisecond.

The package keeps the `waybar-git` name with package release `2`, so pacman owns
the installation. Ansible builds it only when that exact package is not installed.
When updating Waybar, check for an upstream fix before carrying this patch forward.
Changes to the patch require bumping `pkgrel` and the version checked in tasks.

Run the close-event regression check against a patched source checkout:

```sh
python3 test-close-race.py /path/to/Waybar
```

To build manually in this directory:

```sh
makepkg --syncdeps
sudo pacman -U waybar-git-0.15.0.r1004.g6d60c8e-2-x86_64.pkg.tar.zst
```
