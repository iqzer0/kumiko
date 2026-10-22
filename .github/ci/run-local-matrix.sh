#!/bin/sh
#
# Run the CI distro matrix locally with podman: for each distro, build its
# image, then build Kumiko, run the unit tests and the launch smoke test in it.
#
#   .github/ci/run-local-matrix.sh                 # every Dockerfile-* here
#   .github/ci/run-local-matrix.sh fedora arch     # just these
#
# The working tree is copied into each container (uncommitted changes
# included), so containers never write to your checkout. Compiled giD
# packages are shared through a dub cache (KUMIKO_CI_DUB, default
# ~/.cache/kumiko-ci-dub); the first distro fills it, the rest run in
# parallel (KUMIKO_CI_JOBS, default 4). Logs go to KUMIKO_CI_LOGS
# (default .github/ci/ci-logs), one file per distro.
#
set -u
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
cd "$(dirname "$SELF")"
REPO=$(git rev-parse --show-toplevel)
CACHE=${KUMIKO_CI_DUB:-$HOME/.cache/kumiko-ci-dub}
LOGS=${KUMIKO_CI_LOGS:-$PWD/ci-logs}
JOBS=${KUMIKO_CI_JOBS:-4}
mkdir -p "$CACHE" "$LOGS"

# run_one <distro> [fill]: with "fill" the container writes the shared dub
# cache directly (the first, serial run); otherwise it works on a private copy,
# because dub also keeps Kumiko's own build output there and parallel
# containers building the same commit would overwrite each other's objects.
run_one() {
    d=$1
    if [ "${2:-}" = fill ]; then dubmount="$CACHE:/root/.dub"; prep=:
    else dubmount="$CACHE:/dub-shared:ro"; prep="cp -a /dub-shared /root/.dub"; fi
    log="$LOGS/$d.log"
    {
        echo "=== image"
        if ! podman build -q -t "kumiko-ci-$d" -f "Dockerfile-$d" .; then
            echo "RESULT $d: image FAILED"; exit 1
        fi
        echo "=== build, test, smoke"
        if podman run --rm -v "$REPO":/src:ro -v "$dubmount" "kumiko-ci-$d" sh -c '
                set -e
                '"$prep"'
                cp -a /src /work && cd /work
                rm -rf .dub build kumiko kumiko-test-* .rundata
                git config --global --add safe.directory /work
                .github/ci/run-build.sh
                .github/ci/run-tests.sh
                .github/ci/run-smoke.sh
            '; then
            echo "RESULT $d: PASS"
        else
            echo "RESULT $d: FAILED"; exit 1
        fi
    } > "$log" 2>&1
}

if [ "${1:-}" = "--one" ]; then
    (run_one "$2" "${3:-}"); rc=$?; tail -1 "$LOGS/$2.log"; exit $rc
fi

if [ $# -gt 0 ]; then distros="$*"; else distros=$(ls Dockerfile-* | sed 's/^Dockerfile-//'); fi
first=$(echo "$distros" | awk '{print $1}')
rest=$(echo "$distros" | awk '{$1=""; print}')

"$SELF" --one "$first" fill
for d in $rest; do echo "$d"; done | xargs -r -P "$JOBS" -I{} "$SELF" --one {}
echo "logs: $LOGS"
