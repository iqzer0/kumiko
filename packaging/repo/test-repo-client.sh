#!/bin/sh
set -e

# Install Kumiko from the package repository the way the docs tell users to,
# then upgrade it once the repository offers a newer version.
#
# Runs as root in a clean distro image. KUMIKO_REPO_URL is the repository;
# /sync is shared with the driver (run-local-repo-test.sh): this script
# touches /sync/installed after the first install and waits for /sync/go,
# which the driver creates once the server carries the newer version. Ends
# with the launch smoke test against the upgraded install (/src = the repo).

url=${KUMIKO_REPO_URL:?}
. /etc/os-release
echo ">>> $PRETTY_NAME: installing Kumiko from $url"

pkgver() {
    case "$ID $ID_LIKE" in
        *debian*|*ubuntu*) dpkg-query -W -f '${Version}' kumiko ;;
        *) rpm -q --qf '%{VERSION}-%{RELEASE}' kumiko ;;
    esac
}

# --- first install: the documented commands ----------------------------------
case "$ID $ID_LIKE" in
    *debian*|*ubuntu*)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq && apt-get install -yq --no-install-recommends curl ca-certificates
        curl -fsSL "$url/kumiko.gpg" -o /usr/share/keyrings/kumiko.gpg
        curl -fsSL "$url/apt/kumiko.sources" -o /etc/apt/sources.list.d/kumiko.sources
        apt-get update -qq
        apt-get install -yq kumiko
        ;;
    *fedora*)
        curl -fsSL "$url/rpm/kumiko.repo" -o /etc/yum.repos.d/kumiko.repo
        dnf -y install kumiko
        ;;
    *suse*)
        zypper --non-interactive addrepo "$url/rpm/kumiko.repo"
        zypper --non-interactive --gpg-auto-import-keys refresh
        zypper --non-interactive install kumiko
        ;;
    *) echo "!!! no repository for $ID"; exit 1 ;;
esac
first=$(pkgver)
echo ">>> installed kumiko $first"

# --- the repository moves on; upgrade the normal way -------------------------
touch /sync/installed
for i in $(seq 1 600); do [ -e /sync/go ] && break; sleep 1; done
[ -e /sync/go ] || { echo "!!! driver never published the newer version"; exit 1; }

case "$ID $ID_LIKE" in
    *debian*|*ubuntu*) apt-get update -qq && apt-get upgrade -yq ;;
    *fedora*)          dnf -y --refresh upgrade ;;
    *suse*)            zypper --non-interactive refresh && zypper --non-interactive update ;;
esac
second=$(pkgver)
echo ">>> upgraded kumiko $first -> $second"
[ "$second" != "$first" ] || { echo "!!! the upgrade did not pick up the newer version"; exit 1; }

sh /src/.github/ci/install-test-tools.sh
cd /src
SMOKE_INSTALLED=/usr .github/ci/run-smoke.sh
