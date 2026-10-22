Kumiko Release Process
=====================

## Pre-release

1. Ensure `master` branch is up to date:
   ```
   git checkout master && git pull
   ```

2. Verify all CI checks pass on the latest commit.

3. Update version number in:
   - `source/gx/ttyx/constants.d` (`APPLICATION_VERSION`)

4. Write NEWS entries:
   ```
   git shortlog <previous-tag>.. | grep -i -v trivial | grep -v Merge > NEWS.new
   ```
   Then manually edit `NEWS` following this format:
   ```
   Version X.Y.Z
   ~~~~~~~~~~~~~~
   Released: YYYY-MM-DD

   Features:

   Bugfixes:

   Build & Performance:

   Miscellaneous:
   ```
   Note: `appstreamcli news-to-metainfo` only accepts standard section names
   (Features, Bugfixes, Miscellaneous, Notes, Contributors). Use `Features:`
   for security items prefixed with "Security:".

5. Run `extract-strings.sh` to update translation templates.

6. Commit all release prep changes:
   ```
   git commit -a -m "Release version X.Y.Z"
   git push
   ```

## Build and test the packages

7. Tag the release (signed) and push the tag. That starts the **Release
   Packages** workflow: it builds the release binary once on Ubuntu 22.04,
   packages it as `.deb`, `.rpm` and a tarball, then installs each package on
   a clean image of every supported distro and launches it under X11 and
   Wayland. It refuses a tag that does not match `APPLICATION_VERSION`.
    ```
    git tag -s vX.Y.Z -m "Kumiko X.Y.Z"
    git push origin vX.Y.Z
    gh run watch -R iqzer0/kumiko "$(gh run list -R iqzer0/kumiko -w 'Release Packages' -L 1 --json databaseId -q '.[0].databaseId')"
    ```
   Do not publish unless every job is green. To try the pipeline without a
   tag, run the workflow by hand (Actions → Release Packages → Run workflow).

## Sign and checksum

8. Download the packages, add the source archive, and sign one checksum
   file covering everything (the signed tag stays the primary anchor):
    ```
    mkdir -p /tmp/kumiko-X.Y.Z && cd /tmp/kumiko-X.Y.Z
    gh run download -R iqzer0/kumiko <run-id> -n kumiko-packages
    git -C ~/path/to/kumiko archive --format=tar.gz --prefix=kumiko-X.Y.Z/ -o "$PWD/kumiko-X.Y.Z.tar.gz" vX.Y.Z
    rm SHA256SUMS && sha256sum -- *.deb *.rpm *.tar.gz > SHA256SUMS
    gpg --clearsign SHA256SUMS
    ```

## Publish

9. Create the GitHub release **with all assets in one shot** (do NOT
    upload assets after creation — GitHub's immutable releases will
    block subsequent uploads):
    ```
    gh release create vX.Y.Z -R iqzer0/kumiko \
      --title "Kumiko vX.Y.Z" \
      --verify-tag \
      --notes-file /path/to/release-notes.md \
      kumiko_*.deb kumiko-*.rpm kumiko-*-linux-x86_64.tar.gz \
      kumiko-X.Y.Z.tar.gz SHA256SUMS.asc
    ```

10. Publish to the package repositories: run **Publish package
    repositories** in [kumiko-packages](https://github.com/iqzer0/kumiko-packages/actions)
    (Actions → Run workflow), or wait — it runs every 6 hours. It only
    picks up releases whose `SHA256SUMS.asc` verifies against
    `maintainers.asc` there. Check the site lists the new version:
    ```
    curl -fsSL https://iqzer0.github.io/kumiko-packages/apt/dists/stable/main/binary-amd64/Packages | grep ^Version
    ```

11. Update the AUR packages (`kumiko-bin` installs the release tarball,
    `kumiko` builds from source). In clones of their AUR repositories:
    ```
    packaging/aur/update.sh X.Y.Z /tmp/kumiko-X.Y.Z
    # copy packaging/aur/kumiko-bin/PKGBUILD into the kumiko-bin AUR clone,
    # packaging/aur/kumiko/PKGBUILD into the kumiko one, then in each:
    updpkgsums            # kumiko only: fills the source checksums
    makepkg --printsrcinfo > .SRCINFO
    git commit -am "Update to X.Y.Z" && git push
    ```

## Post-release

12. Bump version to next development version in:
    - `source/gx/ttyx/constants.d`

13. Commit and push:
    ```
    git commit -a -m "chore: Post-release version bump to X.Y.Z+1"
    git push
    ```

## Verify

Users can verify release integrity with:
```
# Verify the signed tag (primary)
git verify-tag vX.Y.Z

# Or verify downloads: signature, then checksums
gpg --verify SHA256SUMS.asc
sha256sum --ignore-missing -c SHA256SUMS.asc 2>/dev/null
```

Users install the `.deb`/`.rpm` from the release, `kumiko-bin` or `kumiko`
from the AUR, or build from source — see the Install page (`docs/install.md`).

## Notes

- Kumiko release tags and checksums are signed with the maintainer key
  `7885 F712 AEDF 0761 D231  DB0E 0E06 0BBC C4AE 5E8C` (ed25519, expires 2028-10-21). Before
  it expires, extend it and publish the updated public key:
  `gpg --quick-set-expire 7885F712AEDF0761D231DB0E0E060BBCC4AE5E8C 2y`, then
  `gpg --armor --export 7885F712AEDF0761D231DB0E0E060BBCC4AE5E8C` into
  kumiko-packages' `maintainers.asc` and `gh gpg-key add`. Earlier
  releases: v1.2.0 and v1.3.0-beta.1 were signed with `A63B62EC0FB924FC`
  (also on the iqzer0 GitHub account), releases up to v1.2.0-beta.1 with
  `2CAAD12074F3C056`.
- The package repositories are signed by a separate key,
  `0BD3 837D 9822 8B91 9200  8ADB E0B2 A83C 41E8 0E48`, stored only as the
  `REPO_SIGNING_KEY` secret in kumiko-packages and in the maintainer's
  offline backup (with its revocation certificate). It does not expire;
  if it is ever exposed, publish the revocation and a new key.
- `-inline` is a DMD-only flag and must stay in dub.json's `dflags-dmd`,
  never the compiler-agnostic `dflags` — plain `ldc2` rejects it (LDC's
  `-O3` already enables inlining). Getting this wrong breaks CI and the
  release build identically.
- CI Actions are pinned to commit SHAs (not mutable tags)
- Never create a release then try to add assets — always include them at creation time
