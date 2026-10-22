#!/bin/sh
#
# Install Kumiko build and test dependencies on Arch Linux (also the base of
# Manjaro and EndeavourOS). LDC comes from install-ldc-tarball.sh.
#
set -e
set -x

pacman -Syu --noconfirm --needed \
        appstream \
        base-devel \
        ca-certificates \
        curl \
        dbus \
        desktop-file-utils \
        gettext \
        git \
        glib2 \
        gtk3 \
        libsecret \
        libxml2 \
        po4a \
        vte3 \
        which \
        weston \
        xorg-server-xvfb \
        xz
pacman -Scc --noconfirm
