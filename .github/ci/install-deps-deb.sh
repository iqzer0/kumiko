#!/bin/sh
#
# Install Tilix build dependencies
#
set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# CI passes Azure's Ubuntu mirror (next to GitHub's runners) in
# UBUNTU_MIRROR. It is fast when healthy, but on 2026-10-22 it first refused
# connections and later crawled at ~30 KB/s. Timeouts and a couple of
# retries keep a stalled transfer from hanging the job; apt_try switches
# every source back to the main archive and runs a failed command once more.
# A crawl trips no timeout, since data keeps arriving, so apt_fetch gives
# downloads from the mirror APT_MIRROR_LIMIT seconds (default 300; a healthy
# mirror needs well under a minute) before switching the same way.
printf 'Acquire::Retries "2";\nAcquire::http::Timeout "30";\n' > /etc/apt/apt.conf.d/80kumiko-ci
if [ -n "${UBUNTU_MIRROR:-}" ] && [ "$(. /etc/os-release; echo "$ID")" = ubuntu ]; then
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && sed -i "s|http://archive.ubuntu.com/ubuntu|$UBUNTU_MIRROR|g" "$f"
    done
fi
using_mirror() {
    [ -n "${UBUNTU_MIRROR:-}" ] && grep -qs "$UBUNTU_MIRROR" /etc/apt/sources.list /etc/apt/sources.list.d/*.sources
}
use_main_archive() {
    echo ">>> $UBUNTU_MIRROR $1; switching to ${UBUNTU_FALLBACK:-the main archive}"
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && sed -i "s|$UBUNTU_MIRROR|${UBUNTU_FALLBACK:-http://archive.ubuntu.com/ubuntu}|g" "$f"
    done
    apt-get update -qq
}
apt_try() {
    "$@" && return 0
    using_mirror || return 1
    use_main_archive failed && "$@"
}
# apt_fetch <packages>: download them ahead of the install that follows.
apt_fetch() {
    using_mirror || return 0
    timeout -k 10 "${APT_MIRROR_LIMIT:-300}" apt-get install -yq --download-only "$@" && return 0
    use_main_archive "was too slow or failed"
}

# update caches
apt_try apt-get update -qq

# install build essentials
pkgs="eatmydata build-essential"
apt_fetch $pkgs
apt_try apt-get install -yq $pkgs

# install build dependencies. Note: ldc and its runtime libxml2
# dependency are handled by install-ldc-tarball.sh — ldc is currently
# missing from Debian Testing during a transition, and libxml2 went
# through a SONAME bump in the same suite (libxml2.so.2 → .so.16)
# so the package name varies. curl/xz-utils/ca-certificates are the
# tools install-ldc-tarball.sh needs.
pkgs="appstream
      ca-certificates
      curl
      dbus
      desktop-file-utils
      git
      libatk1.0-dev
      libcairo2-dev
      libglib2.0-dev
      libgtk-3-dev
      libpango1.0-dev
      librsvg2-dev
      libsecret-1-dev
      libvte-2.91-dev
      po4a
      weston
      xvfb
      xz-utils"
apt_fetch $pkgs
apt_try eatmydata apt-get install -yq $pkgs
