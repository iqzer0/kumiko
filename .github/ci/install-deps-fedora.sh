#!/bin/sh
#
# Install Kumiko build and test dependencies on Fedora.
# LDC comes from install-ldc-tarball.sh, as on every CI image.
#
set -e
set -x

dnf -y install --setopt=install_weak_deps=False \
        appstream \
        ca-certificates \
        curl \
        dbus-daemon \
        dbus-tools \
        desktop-file-utils \
        findutils \
        gcc \
        gettext \
        git \
        glib2-devel \
        gtk3-devel \
        libsecret-devel \
        libxml2 \
        po4a \
        tar \
        vte291-devel \
        which \
        weston \
        xorg-x11-server-Xvfb \
        xz
dnf clean all
