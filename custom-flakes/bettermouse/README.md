# BetterMouse

This standalone flake packages the macOS application from the [Homebrew cask
API entry](https://formulae.brew.sh/api/cask/bettermouse.json). Its version,
download URL, SHA-256, product metadata, automatic-update flag, and minimum
macOS version are pinned from that entry rather than fetched dynamically.

The API currently lists version `1.7,8995`, requires macOS 12 or later, and
provides `BetterMouse.1.7.8995.zip`. The cask installs `BetterMouse.app` in
`/Applications` and declares automatic updates; this flake remains pinned
until its metadata is updated.

The derivation extracts the ZIP and places the unchanged app bundle at
`Applications/BetterMouse.app` in the Nix output. It does not run the cask's
install, uninstall, or cleanup actions, or link the app into `/Applications`.
This repository's `nix/` configuration adds the package to the selected user's
Home Manager profile, which links it under
`~/Applications/Home Manager Apps/BetterMouse.app`; any macOS privacy
permissions remain manual. Build it from this directory with:

```sh
nix build .#bettermouse
```

## Updating to a new release

Check the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/bettermouse.json)
for the new `version`, `url`, and `sha256`. To inspect the relevant values:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/bettermouse.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

Update the matching values in the `cask` attribute set in
`custom-flakes/bettermouse/flake.nix`. The cask version may use a comma while
the archive filename uses periods, so keep the API URL as-is rather than
deriving it from `version`. The package extracts `BetterMouse.app` from the
ZIP root; adjust the `installPhase` if the archive layout changes. Keep the
bundle intact (`dontFixup` is set) so its vendor signature is not modified.

From the repository root, validate an update with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/bettermouse
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/bettermouse#bettermouse)/Applications/BetterMouse.app"
codesign --verify --deep --strict "$app"
```