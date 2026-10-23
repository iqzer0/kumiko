#!/bin/sh
set -e

# Build Kumiko's signed package repositories from release packages.
#
#   build-repo.sh <packages-dir> <site-dir>
#
# <packages-dir> holds the .deb and .rpm files of every published release
# (fetch-releases.sh). <site-dir> becomes the static site served by GitHub
# Pages:
#   kumiko.asc / kumiko.gpg   the repository key, armored and binary
#   apt/                      one suite, "stable", for every Debian and Ubuntu
#                             release (the same .deb runs on all of them)
#   rpm/                      for dnf (Fedora) and zypper (openSUSE), with
#                             signed packages and signed metadata
#   rpm/kumiko.repo, apt/kumiko.sources   ready-made client configuration
#
# Signs with KUMIKO_REPO_KEY (a key id or fingerprint) from $GNUPGHOME.
# KUMIKO_REPO_URL is the public base URL the client files point at.
#
# Tools: apt-ftparchive (apt-utils), createrepo_c, rpmsign (rpm), gpg.

in=$(cd "${1:?usage: $0 <packages-dir> <site-dir>}" && pwd)
out=${2:?usage: $0 <packages-dir> <site-dir>}
key=${KUMIKO_REPO_KEY:?set KUMIKO_REPO_KEY to the signing key id}
url=${KUMIKO_REPO_URL:-https://iqzer0.github.io/kumiko-packages}

rm -rf "$out"
mkdir -p "$out/apt/pool/main" "$out/apt/dists/stable/main/binary-amd64" "$out/rpm"
out=$(cd "$out" && pwd)

gpg --batch --armor --export "$key" > "$out/kumiko.asc"
gpg --batch --export "$key" > "$out/kumiko.gpg"
[ -s "$out/kumiko.gpg" ] || { echo "no public key for $key"; exit 1; }

# --- APT ---------------------------------------------------------------------
# apt verifies the signed InRelease, which carries the hash of Packages, which
# carries the hash of every .deb: the packages themselves need no signature.
find "$in" -name '*.deb' -exec cp {} "$out/apt/pool/main/" \;
(
    cd "$out/apt"
    apt-ftparchive packages pool > dists/stable/main/binary-amd64/Packages
    gzip -9kn dists/stable/main/binary-amd64/Packages
    cd dists/stable
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin=Kumiko \
        -o APT::FTPArchive::Release::Label=Kumiko \
        -o APT::FTPArchive::Release::Suite=stable \
        -o APT::FTPArchive::Release::Codename=stable \
        -o APT::FTPArchive::Release::Architectures=amd64 \
        -o APT::FTPArchive::Release::Components=main \
        -o "APT::FTPArchive::Release::Description=Kumiko terminal emulator" \
        release . > /tmp/kumiko-Release
    mv /tmp/kumiko-Release Release
    gpg --batch --yes --local-user "$key" --digest-algo SHA512 --clearsign -o InRelease Release
    gpg --batch --yes --local-user "$key" --digest-algo SHA512 --armor --detach-sign -o Release.gpg Release
)
cat > "$out/apt/kumiko.sources" <<EOF
Types: deb
URIs: $url/apt
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/kumiko.gpg
EOF

# --- RPM ---------------------------------------------------------------------
# Both signatures: the packages (gpgcheck) and the metadata (repo_gpgcheck).
find "$in" -name '*.rpm' -exec cp {} "$out/rpm/" \;
if ls "$out"/rpm/*.rpm >/dev/null 2>&1; then
    # Name gpg explicitly: rpm's default %__gpg differs between distros, and
    # on Ubuntu points at a gpg2 that is not installed.
    rpmsign --define "__gpg $(command -v gpg)" --define "_gpg_name $key" \
        --define "_gpg_digest_algo sha512" --addsign "$out"/rpm/*.rpm
fi
createrepo_c --quiet "$out/rpm"
gpg --batch --yes --local-user "$key" --digest-algo SHA512 --armor --detach-sign \
    -o "$out/rpm/repodata/repomd.xml.asc" "$out/rpm/repodata/repomd.xml"
cat > "$out/rpm/kumiko.repo" <<EOF
[kumiko]
name=Kumiko
type=rpm-md
baseurl=$url/rpm
enabled=1
autorefresh=1
metadata_expire=6h
gpgcheck=1
repo_gpgcheck=1
gpgkey=$url/kumiko.asc
EOF

# --- landing page --------------------------------------------------------------
fpr=$(gpg --batch --with-colons --fingerprint "$key" | awk -F: '/^fpr/{print $10; exit}' | sed 's/.\{4\}/& /g; s/ $//')
cat > "$out/index.html" <<PAGE
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kumiko packages</title>
<style>
  :root { color-scheme: light dark; --fg: #1d1d1f; --bg: #fbfbfd; --code: #eeeef2; --muted: #5a5a66; }
  @media (prefers-color-scheme: dark) { :root { --fg: #e8e8ee; --bg: #121216; --code: #23232b; --muted: #a0a0ad; } }
  body { font: 16px/1.55 system-ui, sans-serif; color: var(--fg); background: var(--bg); max-width: 46rem; margin: 2.5rem auto; padding: 0 16px; }
  pre { background: var(--code); padding: .8rem 1rem; border-radius: 8px; overflow-x: auto; }
  code { font: 14px/1.5 ui-monospace, monospace; }
  .muted { color: var(--muted); }
</style>
</head>
<body>
<h1>Kumiko packages</h1>
<p>Signed package repositories for <a href="https://github.com/iqzer0/kumiko">Kumiko</a>. Add one once and Kumiko updates with the rest of your system.</p>
<h2>Ubuntu, Debian, Linux Mint, Pop!_OS</h2>
<pre><code>sudo curl -fsSLo /usr/share/keyrings/kumiko.gpg $url/kumiko.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/kumiko.sources $url/apt/kumiko.sources
sudo apt update &amp;&amp; sudo apt install kumiko</code></pre>
<h2>Fedora</h2>
<pre><code>sudo curl -fsSLo /etc/yum.repos.d/kumiko.repo $url/rpm/kumiko.repo
sudo dnf install kumiko</code></pre>
<h2>openSUSE Tumbleweed and Leap</h2>
<pre><code>sudo zypper addrepo $url/rpm/kumiko.repo
sudo zypper refresh
sudo zypper install kumiko</code></pre>
<h2>Arch Linux, Manjaro, EndeavourOS</h2>
<p>From the AUR: <code>kumiko-bin</code> (the release build) or <code>kumiko</code> (built from source).</p>
<h2>Repository key</h2>
<p>dnf and zypper ask you to trust this key on first use. Accept it only if the fingerprint matches:</p>
<pre><code>$fpr</code></pre>
<p class="muted">Rebuilt from Kumiko's signed releases every 6 hours.</p>
</body>
</html>
PAGE

debs=$(find "$out/apt/pool" -name '*.deb' | wc -l)
rpms=$(find "$out/rpm" -maxdepth 1 -name '*.rpm' | wc -l)
echo ">>> repository built: $debs .deb, $rpms .rpm, signed by $key"
