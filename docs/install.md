---
title: Install
layout: default
nav_order: 2
permalink: /install/
---

# Install

## Install from the Kumiko repository (recommended)

Add the repository once; after that Kumiko updates with the rest of your
system (`apt upgrade`, `dnf upgrade`, `zypper update`).

```bash
# Ubuntu, Debian, Linux Mint, Pop!_OS, elementary OS, Zorin OS
sudo curl -fsSLo /usr/share/keyrings/kumiko.gpg https://iqzer0.github.io/kumiko-packages/kumiko.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/kumiko.sources https://iqzer0.github.io/kumiko-packages/apt/kumiko.sources
sudo apt update && sudo apt install kumiko

# Fedora
sudo curl -fsSLo /etc/yum.repos.d/kumiko.repo https://iqzer0.github.io/kumiko-packages/rpm/kumiko.repo
sudo dnf install kumiko

# openSUSE Tumbleweed and Leap
sudo zypper addrepo https://iqzer0.github.io/kumiko-packages/rpm/kumiko.repo
sudo zypper refresh
sudo zypper install kumiko

# Arch Linux, Manjaro, EndeavourOS — from the AUR
yay -S kumiko-bin     # the release build; or `kumiko` to build from source
```

dnf and zypper ask you to trust the repository key the first time. Accept it
only if its fingerprint is:

```
D5D9 7A22 F23B 9986 B0FC  F84E ED24 5861 5AA0 8E7B
```

The repository is rebuilt from Kumiko's signed releases every few hours, and
only from releases whose checksums carry the maintainer's signature.

## Install a package file

Each [release](https://github.com/iqzer0/kumiko/releases/latest) also carries
the packages themselves, built from one tested binary. They do not update on
their own. Download the one for your system, then:

```bash
# Ubuntu, Debian, Linux Mint, Pop!_OS, elementary OS, Zorin OS
sudo apt install ./kumiko_X.Y.Z_amd64.deb

# Fedora
sudo dnf install ./kumiko-X.Y.Z-1.x86_64.rpm

# openSUSE (the package is verified by the signed checksums below, not by an RPM signature)
sudo zypper install --allow-unsigned-rpm ./kumiko-X.Y.Z-1.x86_64.rpm

# Arch Linux, Manjaro, EndeavourOS — from the AUR
yay -S kumiko-bin     # the release build; or `kumiko` to build from source
```

Before installing, check the download against the release's signed checksums:

```bash
gpg --verify SHA256SUMS.asc
sha256sum --ignore-missing -c SHA256SUMS.asc
```

Releases are signed with the maintainer key `7885 F712 AEDF 0761 D231  DB0E 0E06 0BBC C4AE 5E8C`.
The packages pull in GTK 3, VTE and libsecret from your distribution and
recommend `gsettings-desktop-schemas` and `dconf`.

---

## Source build

Releases are GPG-signed git tags — verify with `git verify-tag vX.Y.Z`.

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
