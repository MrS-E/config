# Raycast

This standalone flake packages the [Raycast](https://www.raycast.com) macOS
application directly from the vendor's release CDN. The version, ARM64 download
URL and SHA-256 are pinned in `flake.nix` rather than fetched dynamically.

The flake currently packages Raycast `2.7.0.0`. The vendor ships
`Raycast.app` on a DMG; the derivation uses Nixpkgs' `undmg` to extract it and
copies the unchanged bundle to `Applications/Raycast.app` in the Nix output,
exposing the `raycast` binary through `bin/raycast`. It does not run an
installer or link the app into `/Applications`, and it deliberately does not
touch the bundle (`dontFixup` is set) so its vendor signature survives.

Raycast is added to the selected user's Home Manager profile in `nix/`, which
links it under `~/Applications/Home Manager Apps/Raycast.app`. Because the
installed bundle lives in the read-only Nix store, Raycast's own auto-updater
cannot replace it — its update attempts stop the app and then fail to write the
bundle. Bump this flake instead (see below) and disable the in-app updater.

Build the package from this directory with:

```sh
nix build .#raycast
```

## Updating to a new release

Raycast's update script resolves the current release by following the vendor
download redirect. Query the version, URL and SHA-256 with:

```sh
url=$(curl --fail --silent --show-error --head --output /dev/null \
  --write-out '%{redirect_url}' \
  "https://x.raycast-releases.com/download?platform=macos&architecture=arm64")
echo "$url"
echo -n 'sha256-'
curl --fail --silent --show-error --location "$url" \
  | openssl dgst -sha256 -binary | openssl base64
echo
```

Update `cask.version`, `cask.archive.url` and `cask.archive.hash` in
`flake.nix` accordingly, then rebuild. Keep the bundle intact so its vendor
signature is not modified.

From the repository root, validate an update with:

```sh
nix flake check --no-build --no-write-lock-file path:./custom-flakes/raycast
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/raycast#raycast)/Applications/Raycast.app"
codesign --verify --deep --strict "$app"
```

After a successful bump, apply it with `darwin-rebuild switch` so the linked
`~/Applications/Home Manager Apps/Raycast.app` alias points at the new store
path.
