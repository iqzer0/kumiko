#!/bin/sh
#
# Install Kumiko build and test dependencies on openSUSE (Tumbleweed, Leap).
# LDC comes from install-ldc-tarball.sh.
#
set -e
set -x

zypper --non-interactive refresh
zypper --non-interactive install --no-recommends \
        AppStream \
        adwaita-icon-theme \
        ca-certificates \
        curl \
        dejavu-fonts \
        dbus-1 \
        desktop-file-utils \
        findutils \
        gcc \
        gettext-tools \
        git \
        glib2-devel \
        gtk3-devel \
        gzip \
        libsecret-devel \
        libxml2-tools \
        po4a \
        tar \
        vte-devel \
        which \
        weston \
        xorg-x11-server-Xvfb \
        xvfb-run \
        xz
zypper clean --all
