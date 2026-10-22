#!/bin/sh
set -e

# Install a built Kumiko package on a *clean* distro image and launch it.
#
# Runs as root in a stock image (ubuntu:22.04, fedora:latest, ...) with the
# packages mounted at /dist and the repo at /src. The package manager installs
# the package and exactly the dependencies it declares, nothing else of ours,
# so a missing or misnamed dependency fails here. The test tools installed
# afterwards (install-test-tools.sh) are the test bed only: none of them
# provides GTK, VTE or libsecret.

. /etc/os-release
family="$ID $ID_LIKE"
echo ">>> testing the Kumiko package on $PRETTY_NAME"

case "$family" in
    *debian*|*ubuntu*)
        export DEBIAN_FRONTEND=noninteractive
        # Optional faster Ubuntu mirror, as in install-deps-deb.sh.
        if [ -n "${UBUNTU_MIRROR:-}" ] && [ "$ID" = ubuntu ]; then
            for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do
                [ -f "$f" ] && sed -i "s|http://archive.ubuntu.com/ubuntu|$UBUNTU_MIRROR|g" "$f"
            done
        fi
        apt-get update -qq
        apt-get install -yq /dist/kumiko_*_amd64.deb
        ;;
    *fedora*)
        dnf -y install /dist/kumiko-*.x86_64.rpm
        ;;
    *suse*)
        zypper --non-interactive refresh
        zypper --non-interactive install --allow-unsigned-rpm /dist/kumiko-*.x86_64.rpm
        ;;
    *arch*)
        # Arch users install from the AUR: build the kumiko-bin package from
        # packaging/aur/kumiko-bin with the release tarball, as makepkg would.
        pacman -Syu --noconfirm --needed base-devel
        useradd -m builder
        install -d -o builder /home/builder/pkg
        cp /src/packaging/aur/kumiko-bin/PKGBUILD /dist/kumiko-*-linux-x86_64.tar.gz /home/builder/pkg/
        chown -R builder /home/builder/pkg
        su builder -c 'cd ~/pkg && makepkg --noconfirm --nodeps --cleanbuild'
        # --nodeps above only skips makepkg's own check; pacman resolves the
        # PKGBUILD's depends from the repos here, which is what we are testing.
        pacman -U --noconfirm /home/builder/pkg/kumiko-bin-*.pkg.tar.zst
        ;;
    *)
        echo "!!! no package test for $family"; exit 1 ;;
esac

echo ">>> installed: $(command -v kumiko)"
sh /src/.github/ci/install-test-tools.sh
cd /src
SMOKE_INSTALLED=/usr .github/ci/run-smoke.sh
