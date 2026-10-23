# Contributing to Kumiko

Thanks for your interest in contributing to Kumiko!

The [online documentation](https://github.com/iqzer0/kumiko) has install instructions, a user manual, and a changelog. This file covers what you need to **work on Kumiko itself** — setting up a dev environment, running the test suite, submitting changes.

## Prerequisites

- **D compiler**: [LDC](https://github.com/ldc-developers/ldc) 1.40+ recommended. The `dub` package manager ships with it.
- **GTK 3.18+** and **VTE 0.46+** (0.76+ recommended — some features like triggers depend on newer VTE releases) with development headers (`libgtk-3-dev`, `libvte-2.91-dev`, `libsecret-1-dev` on Debian/Ubuntu).
- The GUI bindings are [giD](https://github.com/Kymorphia/gid) (`gid:gtk3`, `gid:vte2`, `gid:secret1`) — a source-only Dub package fetched from the registry and compiled in; nothing D-specific to install system-wide.

See the [Install page](https://github.com/iqzer0/kumiko/blob/master/docs/install.md) for the full system-dependency list.

## Build

Kumiko builds with Dub (the Meson build was retired together with the GtkD bindings):

```bash
dub build --compiler=ldc2                     # debug by default
dub build --build=release --compiler=ldc2     # release
```

The first build compiles the giD binding packages from source and caches them under `~/.dub`; subsequent builds are fast.

## Run from the build dir

The freshly built `./kumiko` doesn't know where to find GSettings schemas or the compiled gresource unless you point it at them:

```bash
glib-compile-schemas data/gsettings/
export GSETTINGS_SCHEMA_DIR="$PWD/data/gsettings"

# The app looks for kumiko/resources/kumiko.gresource under each XDG data dir;
# compile the gresource into such a location:
mkdir -p "$PWD/.rundata/kumiko/resources"
glib-compile-resources --sourcedir=data/resources \
  --target="$PWD/.rundata/kumiko/resources/kumiko.gresource" \
  data/resources/kumiko.gresource.xml
export XDG_DATA_DIRS="$PWD/.rundata:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

./kumiko --new-process
```

Or use the bundled wrapper `debug-kumiko.sh`, which does all of the above plus launches the binary under gdb with sensible defaults.

### Using `debug-kumiko.sh`

```bash
./debug-kumiko.sh              # debug run under gdb
./debug-kumiko.sh --rebuild    # rebuild first, then debug
./debug-kumiko.sh --core       # open most recent coredump via coredumpctl
```

Kumiko is a GTK single-instance application (via D-Bus activation), so the wrapper kills any running `kumiko` before launching under gdb — otherwise the new process would hand off to the existing one and gdb would attach to nothing.

**Gotcha — `kumiko -a <action>` doesn't work against a `debug-kumiko.sh` instance.** The wrapper adds `--new-process`, which disables GApplication's session-bus registration. As a side effect, later `kumiko -a session-add-right …` invocations can't discover the debug instance on the bus, so they fall through to creating a new window and print "No Kumiko instance registered on the session bus…". If you're testing CLI actions, launch Kumiko normally (without the wrapper).

## Tests

### Unit tests

```bash
dub test --compiler=ldc2
```

This builds a test binary that links every module with `-unittest`. Tests live alongside the code they test in `unittest { ... }` blocks — see `source/gx/util/*.d` for straightforward examples. The pure-helper modules (`geometry`, `redact`, `proc`, `string`) exist partly to make logic unit-testable without spinning up GTK widgets.

### Validation tests

CI also runs `desktop-file-validate` against the `.desktop` file (via `install.sh`, which validates on install).

## Debugging

`debug-kumiko.sh` launches gdb with:

- `handle SIG32 SIG33 SIG34 SIG35 SIGPIPE nostop noprint pass` — glibc and GLib use these real-time signals internally (thread cancellation, posix timer expirations, async signal delivery, broken pipe). They're not interesting unless you're specifically hunting a signal bug; the handles let gdb pass them straight through to the app.
- `set print pretty on`, `set pagination off`, `set confirm off` for a friendlier session.

Useful gdb commands once you hit a crash:

- `bt` — backtrace
- `bt full` — backtrace with local variables
- `thread apply all bt` — covers all threads, important for threaded crashes
- `info threads` — list threads
- `continue` — resume after a breakpoint

For a post-mortem on a crash that already happened, `./debug-kumiko.sh --core` opens the most recent Kumiko coredump via `coredumpctl debug`.

## Translations

Kumiko ships 46 locales under `po/`. The gettext template is **generated, not
tracked** — `po/*.pot` is deliberately absent from the repository, so run the
extractor to produce it:

```bash
./extract-strings.sh
```

That regenerates `po/kumiko.pot` from the D sources (via xgettext's Vala mode,
since xgettext has no D backend), the Glade `.ui` files, the `.desktop` and
appdata templates and the Nautilus extension, then `msgmerge`s the result into
every existing `.po` and refreshes `po/LINGUAS`.

**Adding a language:** create `po/<locale>.po` from the generated template
(`msginit -i po/kumiko.pot -l <locale>`), translate, and re-run
`./extract-strings.sh` so `LINGUAS` picks it up.

**Updating a language:** run the extractor first so your `.po` is merged
against current strings, then translate the `#, fuzzy` and untranslated
entries. `msgfmt --statistics -o /dev/null po/<locale>.po` reports where a
locale stands.

Only commit the `.po` files you actually changed — a full extractor run
rewrites line references in all 46, which makes for an unreviewable diff.
`install.sh` compiles the `.po` files at install time; it does **not**
regenerate the template or `LINGUAS`, so translation upkeep is always an
explicit `./extract-strings.sh` run.

## Code style

Enforced by [.editorconfig](.editorconfig) and [dscanner.ini](dscanner.ini). Formatter: [`dfmt`](https://github.com/dlang-community/dfmt).

Key conventions worth knowing:

- **Indentation**: 4 spaces.
- **Brace style**: One True Brace (OTBS).
- **Line length**: 160 soft, 170 hard.
- **Type inference (`auto`)**: default to explicit types. Use `auto` only when the type is already on the RHS (e.g. `auto p = new Process(1);`) or is genuinely unprintable (deep template instantiations). Avoid `auto` for numeric literals (precision mismatches hide behind it), function return values where the callee name doesn't mirror the return type, and associative arrays / slices where the element type carries meaning. Explicit types are documentation the compiler verifies.
- **Comments**: default to none. Add a comment only when the *why* is non-obvious — a hidden constraint, an invariant, a workaround for a specific bug. Don't describe *what* well-named identifiers already express.
- **Tests**: prefer extracting pure testable helpers over integration-heavy fixtures. Many recent refactors lifted pure functions out of GTK-heavy modules specifically to unlock unit tests.

## Submitting changes

1. Fork the repo and create a topic branch off `master`.
2. Make changes, run the test suite, commit.
3. Push and open a PR against `master`.
4. CI builds and runs the unit-test suite in containers of ten distributions (Ubuntu 22.04/24.04/26.04, Debian 12/13/testing, Fedora, Arch, openSUSE Tumbleweed/Leap), then installs into a scratch prefix and launches the installed binary under X11 and Wayland (`.github/ci/run-smoke.sh`). Reproduce any of it locally with `.github/ci/run-local-matrix.sh [distro...]` (podman). PRs need green CI before review.

### Commit and PR conventions

- **Commit subject**: `<category>: short description`, where category is one of `feat`, `fix`, `security`, `refactor`, `docs`, `test`, `style`, `chore`, `ci`. Under 72 chars.
- **Commit body**: explain the *why* rather than the *what*. Surface tradeoffs when a decision has them. Reference issues with `#N`.
- **No AI co-author footers or attribution trailers** — the human committer is the author of record.
- **PR description**: link the issue the PR addresses (`Closes #N` / `Refs #N`), summarize the change, include a test plan.

## Codebase orientation

- `source/app.d` — entry point.
- `source/gx/ttyx/` — core application logic.
  - `application.d` — GTK Application lifecycle, action registration.
  - `appwindow.d` — main window, paned terminal layout.
  - `session.d` — session/workspace management (JSON serialization).
  - `terminal/terminal.d` — the VTE-wrapping terminal widget (largest file in the repo).
  - `terminal/*` — the rest of the terminal stack (spawn, flatpak host bridge, regex, renderer, monitor, state, …).
  - `prefeditor/` — preferences dialog UI.
- `source/gx/gtk/` — GTK utility wrappers (actions, dialogs, color, clipboard, threads, VTE, X11, resources, …).
- `source/gx/util/` — pure helpers with no GTK dependencies (`string`, `geometry`, `redact`, `proc`, `array`, `path`). Easier to unit-test, and the preferred home for logic that doesn't need widget state.
- `source/secret/`, `source/secretc/` — libsecret D and C bindings.
- `source/x11/` — X11 D bindings.
- `data/` — GSettings schema, color schemes, icons, desktop file, AppStream metadata, scripts.
- `docs/` — Jekyll site content published at <https://github.com/iqzer0/kumiko>.
- `po/` — gettext translations.

## License

Kumiko is licensed under [MPL-2.0](LICENSE). Contributions are licensed under the same terms.
