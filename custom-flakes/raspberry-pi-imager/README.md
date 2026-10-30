# Raspberry Pi Imager

This standalone flake packages the macOS app from the [Homebrew cask API
JSON](https://formulae.brew.sh/api/cask/raspberry-pi-imager.json). The pinned
version, download URL, SHA-256, product metadata, and minimum macOS version are
based on that JSON entry; the flake does not fetch cask metadata dynamically.

The cask currently lists version `2.0.11.1`, requires macOS 13 or later, and
installs `Raspberry Pi Imager.app` from
`rpi-imager-v2.0.11.1.dmg`. Build the package from this directory with:

```sh
nix build .#raspberry-pi-imager
```

The DMG is an HFS image, so the flake mounts it read-only with macOS
`hdiutil` and copies the app bundle with `ditto --rsrc --extattr`. This
preserves the app's relative Qt plug-in symlinks, resource forks, and extended
attributes. The bundle is placed at `Applications/Raspberry Pi Imager.app` in
the Nix output; the package does not run Homebrew's uninstall or cleanup
actions or install the app under `/Applications`. This repository's `nix/`
configuration adds it to the selected user's Home Manager profile, which links
it under `~/Applications/Home Manager Apps/Raspberry Pi Imager.app`.

## Updating to a new release

Check the [Homebrew cask API JSON](https://formulae.brew.sh/api/cask/raspberry-pi-imager.json)
for the current metadata. To print the values relevant to this flake:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/raspberry-pi-imager.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

Update the matching values in the `cask` attribute set in
`custom-flakes/raspberry-pi-imager/flake.nix`. Copy the download URL from the
cask metadata rather than deriving it from `version`. Adjust the bundle name or
`installPhase` if the DMG filesystem, layout, or app name changes.

## Verification

Validate an update from the repository root with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/raspberry-pi-imager
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/raspberry-pi-imager#raspberry-pi-imager)/Applications/Raspberry Pi Imager.app"
codesign --verify --deep --strict "$app"
```