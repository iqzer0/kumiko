#!/bin/sh
#
# Install the built packages on clean images of each distro and launch them:
#   .github/ci/run-local-packages.sh <dist-dir> [image...]
# <dist-dir> comes from build-packages.sh. Default images are below; logs go
# to .github/ci/ci-logs/pkg-<image>.log. Needs podman.
#
set -u
SELF=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
REPO=$(cd "$(dirname "$SELF")" && git rev-parse --show-toplevel)
LOGS=$(dirname "$SELF")/ci-logs
JOBS=${KUMIKO_CI_JOBS:-4}
mkdir -p "$LOGS"

if [ "${1:-}" = "--one" ]; then
    dist=$2 image=$3
    log="$LOGS/pkg-$(echo "$image" | tr '/:' '__').log"
    if podman run --rm -v "$REPO":/src:ro -v "$dist":/dist:ro "$image" \
            sh /src/.github/ci/test-package.sh > "$log" 2>&1; then
        echo "PACKAGE $image: PASS"
    else
        echo "PACKAGE $image: FAILED (see $log)"; exit 1
    fi
    exit 0
fi

dist=$(cd "${1:?usage: $0 <dist-dir> [image...]}" && pwd); shift
images=${*:-"ubuntu:22.04 ubuntu:24.04 ubuntu:26.04 debian:bookworm debian:trixie fedora:latest opensuse/leap:16.0 opensuse/tumbleweed archlinux:latest"}
for i in $images; do echo "$i"; done | xargs -P "$JOBS" -I{} "$SELF" --one "$dist" {}
