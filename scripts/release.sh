#!/usr/bin/env bash
#
# release.sh — build the reproducible release asset and print the values to pin.
#
# The installers (install.sh / install.ps1) download a pinned release asset and
# verify its SHA-256 before extracting. This script builds that asset and prints
# the SHA-256 so a maintainer can pin it. It does NOT push tags or create the
# GitHub release — those outward-facing steps are run by hand (see RELEASING.md).
#
# Usage:
#   bash scripts/release.sh <version> [git-ref]
#     version  release tag, e.g. v1.0.0
#     git-ref  ref/commit to archive (default: HEAD)
#
# Output: ./<repo>-<version>.tar.gz  +  its sha256, printed to stdout.
#
# Why a self-built asset (not GitHub's auto-generated source tarball): GitHub
# does not guarantee its `archive/refs/tags/*.tar.gz` is byte-stable over time,
# so a pinned digest of it can spuriously break. `git archive | gzip -n` is
# reproducible (gzip -n drops the mtime/name from the header), so the digest is
# stable across rebuilds of the same ref.
#
# Why the asset excludes the installers/README: they embed the digest, so
# including them would make the hash self-referential. The asset is ONLY the
# install payload — the library plus the validator the installer runs.

set -euo pipefail

VERSION="${1:?usage: bash scripts/release.sh <version> [git-ref]   (e.g. v1.0.0)}"
REF="${2:-HEAD}"

REPO_OWNER="${REPO_OWNER:-LazyIsEfficient}"
REPO_NAME="${REPO_NAME:-agentic-os}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ASSET="$REPO_NAME-$VERSION.tar.gz"
PREFIX="$REPO_NAME-$VERSION/"

# Reproducible payload: .claude (everything the installer copies) + the single
# validator script the installer runs before copying. Nothing else.
git -C "$ROOT" archive --format=tar --prefix="$PREFIX" "$REF" \
    .claude scripts/validate.sh | gzip -n > "$ROOT/$ASSET"

# Fail closed: validate EXACTLY what we packed (extract the asset and run its
# own validator), not the working tree — they can differ when REF != HEAD or the
# tree is dirty. A library that fails the structural invariants is never shipped.
echo "Validating archived payload ($REF) ..." >&2
verify_dir="$(mktemp -d)"
trap 'rm -rf "$verify_dir"' EXIT
tar -xzf "$ROOT/$ASSET" -C "$verify_dir"
if ! bash "$verify_dir/${REPO_NAME}-${VERSION}/scripts/validate.sh" \
         "$verify_dir/${REPO_NAME}-${VERSION}" >&2; then
  rm -f "$ROOT/$ASSET"
  echo "Error: archived payload failed structural validation — asset removed." >&2
  exit 1
fi

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Error: need 'shasum' or 'sha256sum' to compute the digest." >&2
    exit 1
  fi
}

SHA="$(sha256_of "$ROOT/$ASSET")"

cat >&2 <<EOF

Built $ASSET ($(wc -c < "$ROOT/$ASSET" | tr -d ' ') bytes)
  sha256: $SHA

Next steps (see RELEASING.md):
  1. Pin VERSION=$VERSION and EXPECTED_SHA256=$SHA in install.sh and install.ps1,
     and update the version + digest in README.md.
  2. Commit, then tag that commit: git tag $VERSION && git push origin $VERSION
  3. Create the release and upload the asset:
       gh release create $VERSION "$ASSET" -R $REPO_OWNER/$REPO_NAME \\
         --title "$VERSION" --notes-file <notes>
  4. Re-run this script against the tag to confirm the digest is unchanged:
       bash scripts/release.sh $VERSION $VERSION
EOF

# Machine-readable line on stdout for scripting: "<version> <sha256>"
echo "$VERSION $SHA"
