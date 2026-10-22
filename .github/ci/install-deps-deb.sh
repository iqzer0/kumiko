#!/bin/sh
#
# Install Tilix build dependencies
#
set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# Optional faster mirror for Ubuntu (CI passes Azure's, next to GitHub's
# runners). Covers both the classic sources.list and the deb822 format.
if [ -n "${UBUNTU_MIRROR:-}" ] && [ "$(. /etc/os-release; echo "$ID")" = ubuntu ]; then
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
        [ -f "$f" ] && sed -i "s|http://archive.ubuntu.com/ubuntu|$UBUNTU_MIRROR|g" "$f"
    done
fi

# update caches
apt-get update -qq

# install build essentials
apt-get install -yq \
        eatmydata \
        build-essential

# install build dependencies. Note: ldc and its runtime libxml2
# dependency are handled by install-ldc-tarball.sh — ldc is currently
# missing from Debian Testing during a transition, and libxml2 went
# through a SONAME bump in the same suite (libxml2.so.2 → .so.16)
# so the package name varies. curl/xz-utils/ca-certificates are the
# tools install-ldc-tarball.sh needs.
eatmydata apt-get install -yq \
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
