# Creality Print

This standalone flake packages the macOS app from the [Homebrew cask API
JSON](https://formulae.brew.sh/api/cask/creality-print.json). The pinned version,
download URL, SHA-256, product metadata, and automatic-update flag are based on
that JSON entry; the flake does not fetch cask metadata dynamically.

The cask currently lists version `7.2.2.5483,7.2.1` and installs
`Creality Print.app` from the arm64 DMG. Its URL is pinned literally because it
does not follow directly from the comma-separated version. The flake exposes
only `aarch64-darwin`. Build the package from this directory with:

```sh
nix build .#creality-print
```

The DMG uses HFS. The flake mounts it read-only with `hdiutil`, then uses
`ditto --rsrc --extattr` to preserve the app bundle's resource forks and
extended attributes when copying it to `Applications/Creality Print.app` in
the Nix output. The package does not run Homebrew's
uninstall or cleanup actions or install the app under `/Applications`. This
repository's `nix/` configuration adds it to the selected user's Home Manager
profile, which links it under
`~/Applications/Home Manager Apps/Creality Print.app`.

## Updating to a new release

Check the [Homebrew cask API JSON](https://formulae.brew.sh/api/cask/creality-print.json)
for the current metadata. To print the values relevant to this flake:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/creality-print.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

Update the matching values in the `cask` attribute set in
`custom-flakes/creality-print/flake.nix`. Copy the URL from the cask metadata
rather than deriving it from `version`; this cask uses a comma-separated
version and the URL has a distinct version component. Adjust the bundle name or
`installPhase` if the DMG layout or app name changes. Keep the package limited
to systems supported by its selected download URL.

## Verification

Validate an update from the repository root with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/creality-print
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/creality-print#creality-print)/Applications/Creality Print.app"
codesign --verify --deep --strict "$app"
```