#!/bin/sh
set -e

# This script is supposed to run inside the kumiko container on the CI
# system, after run-build.sh.
#
# Unit tests prove the code; this proves the distro can run the result.
# It installs into a throwaway prefix and launches *that* install — so the
# schemas, gresource, icons and translations come from the installed layout,
# not the source tree — with a command that writes a marker file. The marker
# appearing means GTK started, the resources and schemas loaded, VTE spawned
# a child and the child ran. It does so twice:
#   - X11, on Xvfb;
#   - Wayland, on a headless Weston, with XDG_SESSION_TYPE unset the way
#     compositors started from a TTY leave it, and no DISPLAY to fall back on.

# SMOKE_INSTALLED=/usr tests a system-wide install (a distro package)
# instead of installing the source tree into a scratch prefix.
if [ -n "${SMOKE_INSTALLED:-}" ]; then
    PREFIX=$SMOKE_INSTALLED
else
    ROOT=/tmp/smoke_root
    PREFIX=$ROOT/usr
    rm -rf "$ROOT"
    ./install.sh "$PREFIX" > /tmp/kumiko-smoke-install.log 2>&1 || {
        cat /tmp/kumiko-smoke-install.log; exit 1; }
    export GSETTINGS_SCHEMA_DIR="$PREFIX/share/glib-2.0/schemas"
    export XDG_DATA_DIRS="$PREFIX/share:/usr/local/share:/usr/share"
fi
export XDG_CONFIG_HOME=/tmp/smoke_config XDG_CACHE_HOME=/tmp/smoke_cache
export XDG_RUNTIME_DIR=/tmp/smoke_runtime
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
export NO_AT_BRIDGE=1

# A desktop always has fonts; a minimal container may not, and then the
# terminal's cell size is garbage (an 80x24 window overflowed the Wayland
# buffer size on a font-less openSUSE image). Fail on the test bed, clearly.
if command -v fc-match >/dev/null && [ -z "$(fc-match -f '%{family}' monospace 2>/dev/null)" ]; then
    echo "!!! no monospace font installed in this image: add one to its install-deps script"
    exit 1
fi

echo ">>> $PREFIX/bin/kumiko --version"
timeout -k 5 30 "$PREFIX/bin/kumiko" --version < /dev/null

# launch_check <label> <wrapper...>: run the installed kumiko under the given
# wrapper command and require its shell to write the marker. SMOKE_IGNORE may
# hold a regex of known, environment-caused criticals to tolerate.
launch_check() {
    label=$1; shift
    marker=/tmp/kumiko-smoke-$label.marker
    log=/tmp/kumiko-smoke-$label.log
    rm -f "$marker"
    echo ">>> [$label] launching the installed kumiko"
    set +e
    # No terminal input, and a hard kill after the grace period: with a TTY
    # attached (podman run -t in CI), anything in timeout's background process
    # group that touches the terminal is stopped by the kernel, and a stopped
    # process ignores SIGTERM, so a plain timeout could hang the job.
    timeout -k 10 60 "$@" dbus-run-session -- sh -c "
        '$PREFIX/bin/kumiko' --new-process -e \"sh -c 'echo shell-ran > $marker; sleep 3'\" &
        pid=\$!
        for i in \$(seq 1 300); do [ -s '$marker' ] && break; sleep 0.1; done
        sleep 1
        kill \$pid 2>/dev/null
        wait \$pid 2>/dev/null
        exit 0
    " < /dev/null > "$log" 2>&1
    set -e
    # The test bed, not Kumiko: Xvfb occasionally fails to come up (seen on
    # Tumbleweed). Retry once when the log says no display was reachable, and
    # only then, so a failure in Kumiko itself is never retried away.
    if [ "$(cat "$marker" 2>/dev/null)" != "shell-ran" ] && [ -z "${SMOKE_RETRIED:-}" ] \
            && grep -q 'cannot open display' "$log"; then
        echo ">>> [$label] the display did not start; retrying once"
        SMOKE_RETRIED=1 launch_check "$label" "$@"
        return
    fi
    if [ "$(cat "$marker" 2>/dev/null)" != "shell-ran" ]; then
        echo "!!! [$label] FAILED: the terminal's shell never ran"
        cat "$log"
        exit 1
    fi
    # GTK/GLib criticals mean something is broken even if a shell started.
    if grep -E -- '-CRITICAL \*\*|-ERROR \*\*|core dumped|Segmentation fault' "$log" \
            | grep -v -E -- "${SMOKE_IGNORE:-^\$}"; then
        echo "!!! [$label] FAILED: critical errors during launch (above)"
        exit 1
    fi
    echo ">>> [$label] passed: installed kumiko launched and ran its shell"
}

launch_check x11 xvfb-run -a

# Wayland: headless Weston. The backend is spelled "headless" from Weston 10,
# "headless-backend.so" before (Ubuntu 22.04 ships 9).
command -v weston >/dev/null || { echo "!!! weston not installed: cannot run the Wayland pass"; exit 1; }
WL=kumiko-smoke-wl
started=
for backend in headless headless-backend.so; do
    weston --backend=$backend --socket=$WL --idle-time=0 < /dev/null > /tmp/weston.log 2>&1 &
    weston_pid=$!
    for i in $(seq 1 50); do [ -S "$XDG_RUNTIME_DIR/$WL" ] && break; sleep 0.1; done
    if [ -S "$XDG_RUNTIME_DIR/$WL" ]; then started=$backend; break; fi
    kill $weston_pid 2>/dev/null || true; wait $weston_pid 2>/dev/null || true
done
[ -n "$started" ] || { echo "!!! weston did not start"; cat /tmp/weston.log; exit 1; }
echo ">>> weston running (backend $started)"
# Headless Weston has no input devices, so no wl_seat: GTK then asks a NULL
# seat for its keyboard. Real sessions always have a seat, and Kumiko never
# touches seats itself, so that one critical is the test bed, not the app.
SMOKE_IGNORE="gdk_seat_get_keyboard: assertion 'GDK_IS_SEAT \(seat\)' failed" \
    launch_check wayland env -u DISPLAY -u XDG_SESSION_TYPE GDK_BACKEND=wayland WAYLAND_DISPLAY=$WL
kill $weston_pid 2>/dev/null || true; wait $weston_pid 2>/dev/null || true
echo ">>> smoke test passed on X11 and Wayland"
