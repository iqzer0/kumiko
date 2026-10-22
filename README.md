[![Build Test](https://github.com/iqzer0/kumiko/actions/workflows/build-test.yml/badge.svg)](https://github.com/iqzer0/kumiko/actions/workflows/build-test.yml)

<p align="center">
  <img src="data/kumiko.svg" alt="Kumiko logo" width="128">
</p>

# Kumiko

**A tiling terminal for Linux — many panes, one frame.**

*Kumiko* is the Japanese woodworking craft of fitting thin wooden pieces into a lattice without nails. Kumiko the terminal does the same with your shells: split horizontally and vertically, nest as deep as you like, and every pane locks into one window.

Kumiko is inspired by and built on **[ttyx_](https://github.com/gwelr/ttyx_/)** by gwelr and **[Tilix](https://github.com/gnunn1/tilix/)** by Gerald Nunn. It started as a fork of ttyx_, which is itself a fork of Tilix, and carries both forward with a focus on security hardening and on behaving well on modern Linux desktops.

📖 **[Documentation](docs/index.md)** — install, manual, security reference, migration guide, changelog.

## What you get

- **Tiling terminal** — split horizontally, vertically, nest arbitrarily. Drag and drop between windows. Save and restore layouts as sessions. Synchronized input across terminals.
- **Security-conscious by default** — paste review whenever a paste could run commands, bracketed-paste escape stripping, shell-quoted trigger substitutions, root/SSH visual indicators, core-dump protection and in-memory-only scrollback are all on out of the box; clipboard auto-clear and the dangerous-command paste alert are one toggle away. Plus a one-shortcut `Secure Clear`. Full list, including what is *not* covered, on the [Security features page](docs/security.md).
- **No terminal junk** — the mouse wheel never types stray escape codes like `^[OA` into your commands, even in a tab a crashed program or dropped SSH session left in a bad state.
- **Actively maintained** — crash fixes, new color schemes, release-build optimizations, a growing unit-test suite. See [What's new vs Tilix](docs/whats-new.md) for the feature-level comparison and the [changelog](CHANGELOG.md) for per-release notes.

## Install

Kumiko installs from source — build with Dub, install with the bundled `install.sh`:

```bash
dub build --build=release --compiler=ldc2
sudo ./install.sh
```

The [Install page](docs/install.md) has the full walkthrough, including dependencies. Releases are GPG-signed tags.

## Coming from ttyx_ or Tilix

On first run Kumiko carries over what you had:

- **From ttyx_** — your settings (profiles, keybindings, preferences), saved sessions, bookmarks and color schemes, and saved passwords. Nothing of ttyx_'s is deleted, so it keeps working if you go back.
- **From Tilix** — saved sessions and saved passwords.

Terminals get `KUMIKO_ID`, and also `TTYX_ID` and `TILIX_ID`, so existing shell-integration scripts keep working. See [Migrating](docs/migrating.md) for the full checklist and rollback steps.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — build, run, test, debug, code style, and PR conventions.

**Issues** must include what happened, what was expected, reproduction steps, and environment details (distro, VTE version, display server). Incomplete issues will be closed without review.

**Pull requests** are the best way to get something changed. PRs may be declined if they don't fit the project direction — no hard feelings. If you disagree, fork it. That's how this project started too.

This is a freetime project. No support is provided.

## Credits

Kumiko stands on the work of others:

- **[ttyx_](https://github.com/gwelr/ttyx_/)** by gwelr — the actively maintained, security-hardened fork of Tilix that Kumiko grew out of.
- **[Tilix](https://github.com/gnunn1/tilix/)** by Gerald Nunn and its contributors — the original tiling terminal, and the source of much of the manual.
- **[VTE](https://gitlab.gnome.org/GNOME/vte)**, the terminal widget underneath, and **[giD](https://github.com/Kymorphia/gid)**, the D bindings for GTK.

## License

[MPL-2.0](LICENSE). Source files keep the copyright notices of ttyx_ and Tilix, as the license requires.
