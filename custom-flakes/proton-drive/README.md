# Proton Drive

This standalone flake packages the macOS app from the [Homebrew cask API
JSON](https://formulae.brew.sh/api/cask/proton-drive.json). The pinned version,
download URL, SHA-256, product metadata, automatic-update flag, and minimum
macOS version are based on that JSON entry; the flake does not fetch cask
metadata dynamically.

The cask currently lists version `3.0.3`, requires macOS 13 or later, and
installs `Proton Drive.app` from `ProtonDrive-3.0.3.dmg`. Build the package from
this directory with:

```sh
nix build .#proton-drive
```

The DMG uses APFS, so Nixpkgs' HFS-only `undmg` cannot extract it. The flake
uses the pinned upstream 7-Zip 26.03 macOS console binary to read the APFS
image without mounting it, then copies the unchanged app bundle to
`Applications/Proton Drive.app` in the Nix output. The 7-Zip archive URL and
SHA-256 are also pinned in `flake.nix`. The package does not run Homebrew's
uninstall or cleanup actions or install the app under `/Applications`. This
repository's `nix/` configuration adds it to the selected user's Home Manager
profile, which links it under `~/Applications/Home Manager Apps/Proton Drive.app`.
macOS may require additional setup when Proton Drive is first launched.

## Updating to a new release

Check the [Homebrew cask API JSON](https://formulae.brew.sh/api/cask/proton-drive.json)
for the current metadata. To print the values relevant to this flake:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/proton-drive.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

Update the matching values in the `cask` attribute set in
`custom-flakes/proton-drive/flake.nix`. The URL currently follows the version
pattern from the JSON; if Homebrew's URL changes format, copy its new value
instead of assuming the pattern remains valid. Adjust the bundle name or
`installPhase` if the DMG layout or app name changes. The pinned 7-Zip helper
must remain at version 22.00 or later for APFS support; update its download URL
and SHA-256 together if changing that helper.

Validate an update from the repository root with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/proton-drive
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/proton-drive#proton-drive)/Applications/Proton Drive.app"
codesign --verify --deep --strict "$app"
```