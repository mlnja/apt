# apt.mlops.ninja

The apt repository for mlnja tools, served from GitHub Pages. Install
instructions are at <https://apt.mlops.ninja/>.

## How it works

Nothing binary lives in this repo. `scripts/build.sh` downloads the `.deb`
assets of the newest 10 releases of every product in `products.txt`, indexes
them with `apt-ftparchive`, and `scripts/sign.sh` signs the index. The result
is deployed straight to Pages as an artifact. Every run rebuilds from scratch.

It runs on every push here, daily, on demand, and when a product sends a
`repository_dispatch` event of type `release`:

```bash
gh api repos/mlnja/apt/dispatches -f event_type=release
```

From another repo's workflow that needs a token allowed to dispatch here (a
fine-grained PAT or GitHub App token with *Contents: write* on `mlnja/apt`);
the default `GITHUB_TOKEN` can't reach across repos.

## Adding a product

1. Make its release workflow attach `<name>_<version>_<arch>.deb` files.
2. Add `<owner/repo> <package>` to `products.txt`.
3. Optionally, dispatch here after each release so it doesn't wait for the
   daily run.

## Signing key

`APT_SIGNING_KEY` (repository secret) holds the armored private key,
`site/key.asc` the public half.

- Fingerprint: `00DCB9C59B750F4677E50C21CC274C00F0FDDFD5`
- ed25519, signing only, expires 2036-10-24.

Extend before it expires with `gpg --quick-set-expire <fpr> 10y`, then
re-export both halves: users only need to re-download `key.asc`.
