# Texifier

This standalone flake packages the macOS app from the [Homebrew cask API
entry](https://formulae.brew.sh/api/cask/texifier.json). Its version, download
URL, SHA-256 hash, and product metadata are pinned from the cask rather than
fetched dynamically.

The cask currently lists version `1.9.33,855,ddb6e02`, requires macOS 14 or
later, and installs `Texifier.app`. The same disk image is used on Apple Silicon
and Intel. Build the package from this directory with:

```sh
nix build .#texifier
```

The derivation extracts the DMG with Nixpkgs' `undmg` setup hook and places the
unchanged app bundle at `Applications/Texifier.app` in the Nix output. It does
not run the cask's zap actions or link the app into `/Applications`. This
repository's `nix/` configuration adds Texifier to the selected user's Home
Manager profile, which links it under
`~/Applications/Home Manager Apps/Texifier.app`; macOS privacy permissions
remain manual.

## Updating to a new release

Check the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/texifier.json)
for the new version, URL, hash, and metadata. To inspect the relevant values:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/texifier.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts, variations}'
```

Update the matching values in `custom-flakes/texifier/flake.nix`. Adjust the
`installPhase` if the DMG layout or app bundle name changes. Keep the bundle
intact (`dontFixup` is set) so its vendor signature is not modified.

From the repository root, validate an update with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/texifier
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/texifier#texifier)/Applications/Texifier.app"
codesign --verify --deep --strict "$app"
```