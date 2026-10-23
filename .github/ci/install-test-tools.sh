#!/bin/sh
set -e
# Install the launch-test bed on a clean image: virtual display, headless
# Weston, D-Bus, a font (and on openSUSE awk and a cursor theme, which its
# minimal images lack). None of these provides GTK, VTE or libsecret, so
# installing them after Kumiko cannot hide a missing dependency.
. /etc/os-release
case "$ID $ID_LIKE" in
    *debian*|*ubuntu*)
        apt-get install -yq --no-install-recommends xvfb xauth weston dbus fontconfig fonts-dejavu-core ;;
    *fedora*)
        dnf -y install --setopt=install_weak_deps=False xorg-x11-server-Xvfb xorg-x11-xauth which weston \
            dbus-daemon dbus-tools fontconfig dejavu-sans-mono-fonts ;;
    *suse*)
        zypper --non-interactive install --no-recommends xorg-x11-server-Xvfb xvfb-run xauth weston \
            dbus-1 dbus-1-daemon gawk fontconfig dejavu-fonts adwaita-icon-theme ;;
    *arch*)
        pacman -S --noconfirm --needed xorg-server-xvfb xorg-xauth weston dbus fontconfig ttf-dejavu ;;
    *)
        echo "!!! no test tools for $ID"; exit 1 ;;
esac
