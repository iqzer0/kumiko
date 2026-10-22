#!/bin/sh
set -e

# Download the packages of every published Kumiko release.
#
#   fetch-releases.sh <owner/repo> <packages-dir> [maintainer-keys.asc]
#
# Skips drafts, and prereleases unless KUMIKO_INCLUDE_PRERELEASES=1, and
# releases without packages (the old ttyx_ source-only releases).
#
# With maintainer keys, a release is used only if its SHA256SUMS.asc carries a
# good signature from one of them and every package matches its checksum:
# the repository then serves nothing the maintainer did not sign, even if a
# release asset were replaced. Needs gh (GH_TOKEN), gpg, gpgv, sha256sum.

repo=${1:?usage: $0 <owner/repo> <packages-dir> [maintainer-keys.asc]}
dir=${2:?usage: $0 <owner/repo> <packages-dir> [maintainer-keys.asc]}
keys=${3:-}
mkdir -p "$dir"

if [ -n "$keys" ]; then
    keyring=$(mktemp)
    gpg --batch --dearmor < "$keys" > "$keyring"
fi

filter='.[] | select(.isDraft | not)'
[ "${KUMIKO_INCLUDE_PRERELEASES:-0}" = 1 ] || filter="$filter | select(.isPrerelease | not)"
tags=$(gh release list -R "$repo" --limit 200 --json tagName,isDraft,isPrerelease -q "$filter | .tagName")

used=0
for tag in $tags; do
    d="$dir/$tag"
    rm -rf "$d"; mkdir -p "$d"
    if ! gh release download "$tag" -R "$repo" -D "$d" -p '*.deb' -p '*.rpm' -p 'SHA256SUMS.asc' >/dev/null 2>&1 \
            || ! ls "$d"/*.deb "$d"/*.rpm >/dev/null 2>&1; then
        echo "skip $tag: no packages"
        rm -rf "$d"; continue
    fi
    if [ -n "$keys" ]; then
        if [ ! -f "$d/SHA256SUMS.asc" ] \
                || ! gpgv --keyring "$keyring" --output "$d/SHA256SUMS" "$d/SHA256SUMS.asc" 2>/dev/null; then
            echo "skip $tag: SHA256SUMS.asc missing or not signed by a maintainer key"
            rm -rf "$d"; continue
        fi
        ok=1
        for p in "$d"/*.deb "$d"/*.rpm; do
            [ -e "$p" ] || continue
            name=$(basename "$p")
            want=$(awk -v f="$name" '$2 == f || $2 == "*" f {print $1}' "$d/SHA256SUMS")
            have=$(sha256sum "$p" | cut -d' ' -f1)
            if [ -z "$want" ] || [ "$want" != "$have" ]; then
                echo "skip $tag: $name is not covered by the signed checksums"
                ok=0; break
            fi
        done
        [ "$ok" = 1 ] || { rm -rf "$d"; continue; }
    fi
    rm -f "$d/SHA256SUMS" "$d/SHA256SUMS.asc"
    echo "use  $tag: $(ls "$d" | tr '\n' ' ')"
    used=$((used + 1))
done
echo ">>> $used release(s) with packages"
