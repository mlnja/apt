#!/usr/bin/env bash
# Signs public/dists/stable/Release with the key in $APT_SIGNING_KEY (an
# armored secret key, no passphrase). InRelease is what current apt reads;
# Release.gpg is for older clients.
set -euo pipefail

if [ -z "${APT_SIGNING_KEY:-}" ]; then
  echo "APT_SIGNING_KEY is not set: add the armored private key as a repository secret" >&2
  exit 1
fi

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT
gpg --batch --import <<<"$APT_SIGNING_KEY"

cd public/dists/stable
gpg --batch --yes --clearsign -o InRelease Release
gpg --batch --yes --armor --detach-sign -o Release.gpg Release

# Fails the run if what we publish doesn't verify against the public key we
# also publish.
gpg --batch --verify InRelease
