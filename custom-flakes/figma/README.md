# Figma

This standalone flake packages the macOS app from the [Homebrew cask API
entry](https://formulae.brew.sh/api/cask/figma.json). Its version, architecture-
specific download URLs and SHA-256 hashes, and product metadata are pinned from
the cask rather than fetched dynamically.

The cask currently lists version `126.9.11` and installs `Figma.app`. The flake
uses the `mac-arm` archive on Apple Silicon and the `mac` archive on Intel. Build
the package from this directory with:

```sh
nix build .#figma
```

The derivation extracts the ZIP and places the unchanged app bundle at
`Applications/Figma.app` in the Nix output. It does not run the cask's
uninstall or cleanup actions, or link the app into `/Applications`. This
repository's `nix/` configuration adds Figma to the selected user's Home
Manager profile, which links it under
`~/Applications/Home Manager Apps/Figma.app`; macOS privacy permissions remain
manual.

## Updating to a new release

Check the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/figma.json)
for the new version, URLs, hashes, and metadata. To inspect the relevant values:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/figma.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts, variations}'
```

Update the matching values in `custom-flakes/figma/flake.nix`, keeping the ARM
and Intel URLs and hashes paired. Adjust the `installPhase` if the ZIP layout or
app bundle name changes. Keep the bundle intact (`dontFixup` is set) so its
vendor signature is not modified.

From the repository root, validate an update with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/figma
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/figma#figma)/Applications/Figma.app"
codesign --verify --deep --strict "$app"
```