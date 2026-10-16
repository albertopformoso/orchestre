# Cursor theme

`files/Bibata-Modern-Classic.tar.xz` contains a locally rebuilt Xcursor theme from
[Bibata Cursor](https://github.com/ful1e5/Bibata_Cursor), by Abdulkaiz Khatri,
licensed under GPL-3.0 (included in the theme directory).

The theme retains its original name and Modern Classic colors. It includes
sizes **12, 14, 18, and 21** in addition to upstream's standard sizes. Size 21
provides an exact image for applications requesting 14 × 1.5 pixels; individual
toolkits may request other sizes. Upstream cursor aliases, animation frames,
frame delays, and hotspot definitions are preserved.

## Apply

From the repository root, as your normal desktop user:

```sh
ansible-playbook site.yml --tags cursors --ask-become-pass
```

This replaces `/usr/share/icons/Bibata-Modern-Classic/` from the bundled archive,
sets GTK 2/3/4 and desktop-interface cursor settings to 14, and deploys the
repository's Hyprland settings and autostart modules (backing up changed files).
Hyprland uses the Xcursor theme explicitly via `cursor.enable_hyprcursor = false`.
Log out and back in afterward, then reopen Steam and Wine applications.

The `cursors` tag can be used with `--check --diff` first. The full playbook also
installs the theme. Theme deployment does not require internet access or build
tools. Applications supplying their own cursor images may still look different.

Ansible transfers one compressed archive and uses `unarchive` to compare and
extract it, avoiding recursive `copy` checks for every cursor file and alias.
The archive preserves symlinks and readable file/searchable directory permissions.
No `creates` guard is used, so updated archives are applied on later runs.

## Rebuild

Build dependencies: Git, Node.js/npm, and Python with `venv`/pip support.
Run the following in a disposable build directory. The upstream revision and
direct tool versions are pinned; transitive npm dependencies are resolved by npm.

```sh
git clone https://github.com/ful1e5/Bibata_Cursor.git
cd Bibata_Cursor
git checkout ddb09273cde49faeb6a32282660ff4293f52d6e0
npm install --ignore-scripts --no-audit --no-fund cbmp@1.1.1
python -m venv .venv
.venv/bin/pip install clickgen==2.2.0

npx cbmp -d svg/modern -o bitmaps/Bibata-Modern-Classic \
  -bc '#000000' -oc '#FFFFFF' -wc '#000000'

.venv/bin/ctgen configs/normal/x.build.toml \
  -d "$PWD/bitmaps/Bibata-Modern-Classic" -o "$PWD/themes" \
  -n Bibata-Modern-Classic \
  -c 'Black and rounded edge Bibata cursors with additional small sizes' \
  -s 12 14 16 18 20 21 22 24 28 32 40 48 56 64 72 80 88 96 -p x11

cp LICENSE themes/Bibata-Modern-Classic/
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
  --mode='u=rwX,go=rX' -C themes \
  -cJf Bibata-Modern-Classic.tar.xz Bibata-Modern-Classic
```

Copy the resulting `Bibata-Modern-Classic.tar.xz` into this role's `files/`
directory. Packaging requires GNU tar and xz; normalized metadata keeps archives
reproducible for identical build outputs. The renderer produces high-resolution
PNGs from the original SVG artwork; clickgen resamples them into the requested
Xcursor sizes. No resizing of the installed 16-pixel theme is involved.
