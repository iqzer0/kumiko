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
        # CI passes Azure's Ubuntu mirror (next to GitHub's runners) in
        # UBUNTU_MIRROR, with the same fallbacks as install-deps-deb.sh: apt_try
        # reruns a failed command against the main archive, and apt_fetch
        # switches there when downloads from the mirror take longer than
        # APT_MIRROR_LIMIT seconds (default 300), as they did at ~30 KB/s on
        # 2026-10-22.
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
        apt_fetch() {
            using_mirror || return 0
            timeout -k 10 "${APT_MIRROR_LIMIT:-300}" apt-get install -yq --download-only "$@" && return 0
            use_main_archive "was too slow or failed"
        }
        apt_try apt-get update -qq
        apt_fetch /dist/kumiko_*_amd64.deb
        apt_try apt-get install -yq /dist/kumiko_*_amd64.deb
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
