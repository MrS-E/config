# Proton Mail Bridge

This standalone flake packages the macOS app from the [Homebrew cask API
JSON](https://formulae.brew.sh/api/cask/proton-mail-bridge.json). The pinned
version, download URL, SHA-256, product metadata, and automatic-update flag are
based on that JSON entry; the flake does not fetch cask metadata dynamically.

The cask currently lists version `3.27.0` and installs `Proton Mail Bridge.app`
from `Bridge-Installer.dmg`. Build the package from this directory with:

```sh
nix build .#proton-mail-bridge
```

The DMG uses HFS+, so the flake mounts it read-only with macOS `hdiutil` and
copies the app bundle with `ditto --rsrc --extattr`. This preserves the app's
resource forks and extended attributes, including its Proton Developer ID
signature and notarization. The package does not run Homebrew's uninstall or
cleanup actions or install the app under `/Applications`. This repository's
`nix/` configuration adds it to the selected user's Home Manager profile,
which links it under `~/Applications/Home Manager Apps/Proton Mail Bridge.app`.

## Updating to a new release

Check the [Homebrew cask API JSON](https://formulae.brew.sh/api/cask/proton-mail-bridge.json)
for the current metadata. To print the values relevant to this flake:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/proton-mail-bridge.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

Update the matching values in the `cask` attribute set in
`custom-flakes/proton-mail-bridge/flake.nix`. Copy the cask's current download
URL rather than assuming its format will remain unchanged. Adjust the bundle
name or `installPhase` if the DMG layout or app name changes; keep the
metadata-preserving copy because ordinary recursive copying invalidates the
app's code signature.

Validate an update from the repository root with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/proton-mail-bridge
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/proton-mail-bridge#proton-mail-bridge)/Applications/Proton Mail Bridge.app"
codesign --verify --deep --strict "$app"
```