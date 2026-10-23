#!/bin/sh
# Point both AUR recipes at a release: packaging/aur/update.sh 1.4.0 [dist-dir]
# Sets _ver/pkgver (Arch versions take no hyphen: 1.4.0-rc.1 -> 1.4.0rc.1),
# resets pkgrel, and fills kumiko-bin's checksum from dist-dir/SHA256SUMS.
# Then regenerate .SRCINFO with `makepkg --printsrcinfo > .SRCINFO` per recipe.
set -e
ver=$1; dist=${2:-dist}
[ -n "$ver" ] || { echo "usage: $0 <version> [dist-dir]"; exit 1; }
here=$(dirname "$0")
pkgver=$(echo "$ver" | tr -d -)
for f in "$here/kumiko-bin/PKGBUILD" "$here/kumiko/PKGBUILD"; do
    sed -i -e "s/^_ver=.*/_ver=$ver/" -e "s/^pkgver=.*/pkgver=$pkgver/" -e "s/^pkgrel=.*/pkgrel=1/" "$f"
done
sum=$(awk -v f="kumiko-$ver-linux-x86_64.tar.gz" '$2 == f {print $1}' "$dist/SHA256SUMS")
[ -n "$sum" ] || { echo "no checksum for kumiko-$ver-linux-x86_64.tar.gz in $dist/SHA256SUMS"; exit 1; }
sed -i "s/^sha256sums=('[^']*')/sha256sums=('$sum')/" "$here/kumiko-bin/PKGBUILD"
echo "AUR recipes now point at $ver"
