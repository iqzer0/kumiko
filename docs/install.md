---
title: Install
layout: default
nav_order: 2
permalink: /install/
---

# Install

Kumiko installs from source: build with Dub, install with the bundled
`install.sh`. Releases are GPG-signed git tags — verify with
`git verify-tag vX.Y.Z` (or check the signed checksums attached to the
[latest release](https://github.com/iqzer0/kumiko/releases/latest)).

---

## Source build

### Supported distributions

Every change is built, unit-tested, installed into a scratch prefix and launched — under X11 and under Wayland — in CI containers of:

| Family | Releases | Also covers |
|---|---|---|
| Ubuntu | 22.04 LTS, 24.04 LTS, 26.04 LTS | Linux Mint, Pop!_OS, elementary OS, Zorin OS |
| Debian | 12 (bookworm), 13 (trixie), testing | |
| Fedora | latest release | |
| Arch Linux | rolling | Manjaro, EndeavourOS |
| openSUSE | Tumbleweed, Leap 16 | |

Run the same checks on your machine with `.github/ci/run-local-matrix.sh [distro...]` (needs podman).

### Requirements

- GTK 3.24 and VTE 0.68 or newer (the oldest tested combination is Ubuntu 22.04's)
- libsecret, for the password manager
- Recommended at runtime: `gsettings-desktop-schemas` (system monospace font, dark-mode preference, proxy settings — Kumiko falls back to defaults without it) and the `dconf` command-line tool (one-time import of ttyx_ settings)
- To build: LDC 1.40 or newer. CI installs the upstream [1.40.0 release](https://github.com/ldc-developers/ldc/releases/tag/v1.40.0) on every distro; a distro `ldc` package works if it is at least that new.

### Building with Dub (the build system)

Kumiko builds with [Dub](https://dub.pm/) against the [giD](https://github.com/Kymorphia/gid)
GObject-Introspection bindings (`gid:gtk3`, `gid:vte2`, `gid:secret1`). giD is a
source-only Dub package compiled into the binary, so — unlike the old GtkD
bindings — nothing D-specific needs to be installed system-wide. (The Meson
build was retired together with GtkD.)

**Build dependencies** (the same packages CI installs, minus its test-only tools):

```bash
# Debian / Ubuntu
sudo apt-get install build-essential libgtk-3-dev libvte-2.91-dev libsecret-1-dev \
  gettext desktop-file-utils gtk-update-icon-cache xdg-utils

# Fedora
sudo dnf install gcc gtk3-devel vte291-devel libsecret-devel \
  gettext desktop-file-utils xdg-utils

# Arch Linux
sudo pacman -S --needed base-devel gtk3 vte3 libsecret \
  gettext desktop-file-utils xdg-utils

# openSUSE
sudo zypper install gcc gtk3-devel vte-devel libsecret-devel \
  gettext-tools desktop-file-utils xdg-utils
```

**Build, test, install:**

```bash
dub build --build=release --compiler=ldc2

# Unit tests:
dub test --compiler=ldc2

# Install (binary + schemas, gresource, icons, translations, man page):
sudo ./install.sh
```

**Offline / vendored builds** (distro packaging, sandboxed builds): download
the giD package archive from
`https://code.dlang.org/packages/gid/0.9.13.zip`, then:

```bash
unzip gid-0.9.13.zip
export DUB_HOME=$PWD/.dub
dub add-local gid-0.9.13 0.9.13
dub build --build=release --compiler=ldc2 --skip-registry=all
```

---

## First launch

On first run:

- If you previously used ttyx_ or Tilix, Kumiko [carries over]({{ site.baseurl }}/migrating/) your settings, sessions and saved passwords.
- The terminal opens with the default profile. Preferences live under **Hamburger menu → Preferences** (or `Ctrl+,`).
- Security options are consolidated under **Preferences → Advanced → Security**.

---

## Troubleshooting

### App icon shows as a broken placeholder

Typically a stale icon cache from a previous install. Refresh the icon cache for your install prefix and let GTK regenerate it:

```bash
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/
```

Then relaunch Kumiko.

### Quake mode doesn't position correctly on Wayland

See the [Wayland section on the Quake manual page]({{ site.baseurl }}/manual/quake/#wayland) for compositor-specific notes and workarounds.
