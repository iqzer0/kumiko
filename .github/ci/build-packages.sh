#!/bin/sh
set -e

# Build the release binary once and package it into ./dist:
#   kumiko_<ver>_amd64.deb         Ubuntu, Debian and derivatives
#   kumiko-<ver>.x86_64.rpm        Fedora, openSUSE
#   kumiko-<ver>-linux-x86_64.tar.gz   the installed tree (AUR kumiko-bin, manual)
#   SHA256SUMS                     to be GPG-signed by the maintainer (RELEASE.md)
#
# Runs in the Ubuntu 22.04 CI image on purpose: it has the oldest glibc we
# support, and a binary built against an older glibc runs on every newer one,
# so one build serves every distro. The binary links only libc, libm,
# libgcc_s, libX11 and libgdk-3 (the D runtime is static; GTK, VTE and
# libsecret are loaded at runtime), which packaging/nfpm.yaml declares.

VERSION=${KUMIKO_VERSION:-$(sed -n 's/^enum APPLICATION_VERSION = "\(.*\)";/\1/p' source/gx/ttyx/constants.d)}
[ -n "$VERSION" ] || { echo "cannot determine version"; exit 1; }

# nfpm builds .deb and .rpm from one config without distro tooling. Pinned and
# checksummed: https://github.com/goreleaser/nfpm/releases/tag/v2.47.0
NFPM_VERSION=2.47.0
NFPM_SHA256=0660ca602b2d2d2ae4781a06c692b3eeb9d437ffea05b831d76e41f4a3188783

echo ">>> building Kumiko $VERSION (release)"
dub build --compiler=ldc2 --build=release

rm -rf stage dist
mkdir -p dist
./install.sh "$PWD/stage/usr" > /tmp/kumiko-stage.log 2>&1 || { cat /tmp/kumiko-stage.log; exit 1; }
# Caches are per-system; the package's install scripts and triggers rebuild them.
rm -f stage/usr/share/glib-2.0/schemas/gschemas.compiled \
      stage/usr/share/icons/hicolor/icon-theme.cache \
      stage/usr/share/applications/mimeinfo.cache
strip --strip-unneeded stage/usr/bin/kumiko

if ! command -v nfpm >/dev/null; then
    curl -fsSL -o /tmp/nfpm.tgz \
        "https://github.com/goreleaser/nfpm/releases/download/v${NFPM_VERSION}/nfpm_${NFPM_VERSION}_Linux_x86_64.tar.gz"
    echo "${NFPM_SHA256}  /tmp/nfpm.tgz" | sha256sum -c -
    tar -xzf /tmp/nfpm.tgz -C /usr/local/bin nfpm
fi

export KUMIKO_VERSION="$VERSION"
nfpm package -f packaging/nfpm.yaml -p deb -t dist/
nfpm package -f packaging/nfpm.yaml -p rpm -t dist/
tar -C stage --owner=0 --group=0 -czf "dist/kumiko-${VERSION}-linux-x86_64.tar.gz" usr
(cd dist && sha256sum -- * > SHA256SUMS)

echo ">>> packages for $VERSION:"
ls -l dist/
