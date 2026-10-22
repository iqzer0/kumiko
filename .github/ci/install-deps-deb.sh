#!/bin/sh
#
# Install Tilix build dependencies
#
set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# CI passes Azure's Ubuntu mirror (next to GitHub's runners) in
# UBUNTU_MIRROR. It is fast when it answers; when it does not (refused
# connections, seen in CI on 2026-10-22), apt_try switches every source back
# to the main archive and runs the failed command once more. Timeouts and a
# couple of retries keep a stalled transfer from hanging the job.
printf 'Acquire::Retries "2";\nAcquire::http::Timeout "30";\n' > /etc/apt/apt.conf.d/80kumiko-ci
if [ -n "${UBUNTU_MIRROR:-}" ] && [ "$(. /etc/os-release; echo "$ID")" = ubuntu ]; then
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && sed -i "s|http://archive.ubuntu.com/ubuntu|$UBUNTU_MIRROR|g" "$f"
    done
fi
apt_try() {
    "$@" && return 0
    [ -n "${UBUNTU_MIRROR:-}" ] && grep -qs "$UBUNTU_MIRROR" /etc/apt/sources.list /etc/apt/sources.list.d/*.sources || return 1
    echo ">>> $UBUNTU_MIRROR failed; switching to ${UBUNTU_FALLBACK:-the main archive} and retrying"
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && sed -i "s|$UBUNTU_MIRROR|${UBUNTU_FALLBACK:-http://archive.ubuntu.com/ubuntu}|g" "$f"
    done
    apt-get update -qq && "$@"
}

# update caches
apt_try apt-get update -qq

# install build essentials
apt_try apt-get install -yq \
        eatmydata \
        build-essential

# install build dependencies. Note: ldc and its runtime libxml2
# dependency are handled by install-ldc-tarball.sh — ldc is currently
# missing from Debian Testing during a transition, and libxml2 went
# through a SONAME bump in the same suite (libxml2.so.2 → .so.16)
# so the package name varies. curl/xz-utils/ca-certificates are the
# tools install-ldc-tarball.sh needs.
apt_try eatmydata apt-get install -yq \
        appstream \
        ca-certificates \
        curl \
        dbus \
        desktop-file-utils \
        git \
        libatk1.0-dev \
        libcairo2-dev \
        libglib2.0-dev \
        libgtk-3-dev \
        libpango1.0-dev \
        librsvg2-dev \
        libsecret-1-dev \
        libvte-2.91-dev \
        po4a \
        weston \
        xvfb \
        xz-utils
