#!/usr/bin/env bash
# Builds the whole apt repository into public/ from the products' GitHub
# releases. Stateless on purpose: the .deb files live in each product's
# releases, never in this repo's git history, so a rebuild from scratch is
# the only kind there is.
set -euo pipefail

KEEP="${KEEP:-10}"
ARCHES="amd64 arm64"
OUT=public

rm -rf "$OUT"
cp -r site "$OUT"

grep -Ev '^\s*(#|$)' products.txt | while read -r repo pkg; do
  dir="$OUT/pool/main/${pkg:0:1}/$pkg"
  mkdir -p "$dir"
  tags=$(gh release list -R "$repo" -L "$KEEP" --exclude-drafts --exclude-pre-releases \
    --json tagName -q '.[].tagName')
  for tag in $tags; do
    # Releases cut before a product shipped .debs simply have none.
    if gh release view "$tag" -R "$repo" --json assets -q '.assets[].name' | grep -q '\.deb$'; then
      gh release download "$tag" -R "$repo" -p '*.deb' -D "$dir"
    else
      echo "$repo $tag: no .deb assets, skipped"
    fi
  done
done

cd "$OUT"
for arch in $ARCHES; do
  d="dists/stable/main/binary-$arch"
  mkdir -p "$d"
  apt-ftparchive --arch "$arch" packages pool > "$d/Packages"
  gzip -9kn "$d/Packages"
done

# Written outside dists/ first, or the Release file would list itself.
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="mlops.ninja" \
  -o APT::FTPArchive::Release::Label="mlops.ninja" \
  -o APT::FTPArchive::Release::Suite="stable" \
  -o APT::FTPArchive::Release::Codename="stable" \
  -o APT::FTPArchive::Release::Architectures="$ARCHES" \
  -o APT::FTPArchive::Release::Components="main" \
  release dists/stable > ../Release.tmp
mv ../Release.tmp dists/stable/Release

find pool -name '*.deb' | sort
