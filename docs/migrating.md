---
title: Migrating to Kumiko
layout: default
nav_order: 5
permalink: /migrating/
---

# Migrating to Kumiko

Kumiko descends from [ttyx_](https://github.com/gwelr/ttyx_/), which descends from [Tilix](https://github.com/gnunn1/tilix/). Coming from either, Kumiko carries your setup over automatically on first run. You shouldn't need to do anything by hand; this page describes what happens and how to check it.

## From ttyx_

On first launch Kumiko copies — never moves — what ttyx_ left behind:

- **Settings**: profiles, keybindings and every preference, from ttyx_'s dconf tree `/io/github/gwelr/ttyx/` to Kumiko's `/io/github/iqzer0/kumiko/`. This runs only while Kumiko has no settings of its own, and uses the `dconf` command-line tool (GSettings cannot read a schema that is no longer installed). Without `dconf`, Kumiko starts with defaults; copy the settings yourself with `dconf dump /io/github/gwelr/ttyx/ | dconf load /io/github/iqzer0/kumiko/`.
- **Config directory**: `~/.config/ttyx/` (saved sessions, bookmarks, custom color schemes) is copied to `~/.config/kumiko/` with the same symlink-safe routine described below for Tilix.
- **Saved passwords**: entries stored under ttyx_'s schema (`io.github.gwelr.ttyx.Password`) stay listed, usable, editable and deletable. New ones are saved under `io.github.iqzer0.kumiko.Password`.
- **Shell integration**: terminals get `KUMIKO_ID`, and still `TTYX_ID` and `TILIX_ID`; `kumiko_int.sh` also honours `TTYX_SILENT`.

What you update yourself:

- **The command** is now `kumiko`. Scripts and keyboard shortcuts that run `ttyx` need changing.
- **The integration script** moved from `/usr/share/ttyx/scripts/ttyx_int.sh` to `/usr/share/kumiko/scripts/kumiko_int.sh`. Copies you placed on remote hosts keep working as they are.
- **Custom CSS** that targets ttyx_'s style classes: `.ttyx-*` classes are now `.kumiko-*`.

Kumiko and ttyx_ can be installed side by side — their commands, app IDs, settings and files don't overlap — and ttyx_'s settings and config are left untouched, so going back is just running `ttyx` again. To remove ttyx_, run its `uninstall.sh` from a ttyx_ checkout (`sudo ./uninstall.sh`), then delete `~/.config/ttyx/` and `dconf reset -f /io/github/gwelr/ttyx/` once you no longer need them.

## From Tilix

### What Kumiko migrates automatically

On first launch, if Kumiko detects `~/.config/tilix/` and no pre-existing `~/.config/kumiko/`, it performs the following:

- **Session files**: `~/.config/tilix/` is copied (not moved) to `~/.config/kumiko/`. The original directory is left in place as a backup until you decide to remove it.
- **Saved passwords**: existing entries stored in libsecret under the old Tilix schema (`com.gexperts.tilix.Password`) are still readable by the password manager. New passwords you save from Kumiko go under the new schema (`io.github.iqzer0.kumiko.Password`), and deleting an entry removes it from whichever schema it was stored in.
- **Shell integration**: terminals spawned by Kumiko set `TILIX_ID` (alongside `KUMIKO_ID` and `TTYX_ID`), so existing shell-integration scripts (e.g. `tilix_int.sh`, now shipped as [`kumiko_int.sh`]({{ site.baseurl }}/manual/profileswitch/#remote-configuration) for new installs) continue to work during the transition.

The migration is idempotent: if `~/.config/kumiko/` already exists, Kumiko leaves everything alone and starts normally.

### Security: symlink safety

The migration refuses to follow symlinks during the copy. If a file in the source tree is a symlink (whether into or out of `~/.config/tilix/`), that entry is skipped and a warning is logged. This avoids a class of symlink-swap attacks where an attacker could redirect the migration to write outside your config directory.

If you've set up legitimate symlinks inside `~/.config/tilix/` — for example syncing a subset of files via Syncthing — those entries will not be migrated. Either dereference them before first launch, or recreate them manually inside `~/.config/kumiko/` after launch.

### What is *not* migrated

- **GSettings preferences** (keybindings, profiles, global app settings). Kumiko uses its own schema at `io.github.iqzer0.kumiko` rather than `com.gexperts.Tilix`, and GSettings does not provide an automatic migration path between schemas. **Configure preferences in Kumiko directly** on first launch. If you had an unusual setup under Tilix, keep a Tilix window open side-by-side to mirror the settings.
- **Desktop entry overrides**: if you had a customized `~/.local/share/applications/com.gexperts.Tilix.desktop`, those changes don't carry over; Kumiko ships its own desktop file under `io.github.iqzer0.kumiko.desktop`.

### Verifying the migration

After first launch:

```bash
# Config dir is populated
ls ~/.config/kumiko/

# Original Tilix config is still in place
ls ~/.config/tilix/

# Saved passwords are readable (open the password manager and check the list)
# Shell inside a Kumiko terminal:
echo "KUMIKO_ID=$KUMIKO_ID TTYX_ID=$TTYX_ID TILIX_ID=$TILIX_ID"
```

All three should be set to the same UUID. Your saved passwords should be visible in **Preferences → Password Manager**.

### Rolling back

If something looks wrong and you want to revert to Tilix:

1. Close Kumiko.
2. Your original Tilix config is still at `~/.config/tilix/` — launch `tilix` and it will pick up from where it was.
3. Optionally delete `~/.config/kumiko/` if you want a clean slate before trying Kumiko again.

Because migration only copies and never modifies the source, there is nothing to "undo" on the Tilix side.

### Removing the old Tilix config

Once you've confirmed Kumiko is working the way you want, the Tilix backup is safe to remove:

```bash
rm -rf ~/.config/tilix/
```

You can do this at any time — Kumiko no longer reads from `~/.config/tilix/` after the initial migration.

### Uninstalling Tilix itself

Kumiko and Tilix can coexist on the same system; their binaries, icons, desktop files, and GSettings schemas don't collide. If you don't want Tilix installed anymore, uninstall it however your distro or package manager prefers (`apt remove tilix`, `flatpak uninstall com.gexperts.Tilix`, etc.) — that's independent of the Kumiko migration.
