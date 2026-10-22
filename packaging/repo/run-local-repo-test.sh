#!/bin/sh
#
# End-to-end test of the package repositories, locally, with podman:
#
#   packaging/repo/run-local-repo-test.sh <dist-old> <dist-new> [image...]
#
# <dist-old>, <dist-new>: build-packages.sh output for two versions.
# A throwaway signing key builds two repositories (old; old + new), a small
# web server in a pod serves the first, and each clean client image installs
# Kumiko the documented way (test-repo-client.sh). Once every client has
# installed, the server switches to the second repository and the clients
# upgrade with their normal command, then launch the result. Nothing here
# touches your real keys: the key lives and dies in a temporary GNUPGHOME.
#
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here" && git rev-parse --show-toplevel)
old=$(cd "${1:?usage: $0 <dist-old> <dist-new> [image...]}" && pwd)
new=$(cd "${2:?usage: $0 <dist-old> <dist-new> [image...]}" && pwd); shift 2
images=${*:-"ubuntu:22.04 ubuntu:24.04 ubuntu:26.04 debian:bookworm debian:trixie fedora:latest opensuse/leap:16.0 opensuse/tumbleweed"}
work=$(mktemp -d "${TMPDIR:-/tmp}/kumiko-repo-test.XXXXXX")
pod=kumiko-repo-test-$$
url=http://localhost:8000
trap 'podman pod rm -f "$pod" >/dev/null 2>&1; rm -rf "$work"' EXIT

echo ">>> throwaway signing key and both repositories"
mkdir -p "$work/gnupg" "$work/in-old" "$work/in-new"
chmod 700 "$work/gnupg"
cp "$old"/*.deb "$old"/*.rpm "$work/in-old/"
cp "$old"/*.deb "$old"/*.rpm "$new"/*.deb "$new"/*.rpm "$work/in-new/"
podman run --rm -v "$repo":/src:ro -v "$work":/w -e GNUPGHOME=/w/gnupg -e KUMIKO_REPO_URL=$url \
        docker.io/library/ubuntu:24.04 sh -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get install -yq --no-install-recommends apt-utils createrepo-c rpm gnupg >/dev/null
    gpg --batch --pinentry-mode loopback --passphrase "" --quick-gen-key "Kumiko test repository key (throwaway)" rsa4096 sign 1d
    export KUMIKO_REPO_KEY=$(gpg --list-secret-keys --with-colons | awk -F: "/^fpr/{print \$10; exit}")
    sh /src/packaging/repo/build-repo.sh /w/in-old /w/site-old
    sh /src/packaging/repo/build-repo.sh /w/in-new /w/site-new
' > "$work/build.log" 2>&1 || { cat "$work/build.log"; exit 1; }
grep '>>> repository built' "$work/build.log"

serve() {
    podman rm -f "$pod-web" >/dev/null 2>&1
    podman run -d --pod "$pod" --name "$pod-web" -v "$1":/srv:ro docker.io/library/busybox:1.36 \
        httpd -f -p 8000 -h /srv >/dev/null
}
podman pod create --name "$pod" >/dev/null
serve "$work/site-old"

echo ">>> clients install from the old repository"
n=0
for img in $images; do
    n=$((n + 1)); s="$work/sync-$n"; mkdir -p "$s"
    echo "$img" > "$s/image"
    podman run -d --pod "$pod" --name "$pod-c$n" -e KUMIKO_REPO_URL=$url \
        -v "$repo":/src:ro -v "$s":/sync "$img" sh /src/packaging/repo/test-repo-client.sh >/dev/null
done

# Wait until every client has installed (or exited early on failure).
for i in $(seq 1 1800); do
    pending=0
    for c in $(seq 1 $n); do
        [ -e "$work/sync-$c/installed" ] && continue
        [ "$(podman inspect -f '{{.State.Running}}' "$pod-c$c" 2>/dev/null)" = true ] && pending=1
    done
    [ $pending = 0 ] && break
    sleep 1
done

echo ">>> server now offers the newer version; clients upgrade"
serve "$work/site-new"
for c in $(seq 1 $n); do touch "$work/sync-$c/go"; done

fail=0
for c in $(seq 1 $n); do
    img=$(cat "$work/sync-$c/image")
    rc=$(podman wait "$pod-c$c")
    log="$here/../../.github/ci/ci-logs/repo-$(echo "$img" | tr '/:' '__').log"
    mkdir -p "$(dirname "$log")"; podman logs "$pod-c$c" > "$log" 2>&1
    up=$(grep -o 'upgraded kumiko .*' "$log" | head -1)
    if [ "$rc" = 0 ]; then echo "REPO $img: PASS ($up)"; else echo "REPO $img: FAILED (see $log)"; fail=1; fi
done
exit $fail
