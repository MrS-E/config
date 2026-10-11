# Nextcloud VFS

This standalone flake packages the macOS application from the installer
described by the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/nextcloud-vfs.json).
Its version, download URL, SHA-256, product metadata, macOS requirement,
conflict, and deprecation details are copied from that entry; the values are
pinned here rather than fetched dynamically.

The API entry currently lists version `4.0.8`, requires macOS 12 or later, and
marks the cask discontinued as of 2026-04-01, with `nextcloud` as its
replacement. Although the cask declares automatic updates, this flake remains
pinned until its metadata is updated.

The flake uses `nixpkgs-26.05-darwin` to retain an `x86_64-darwin` output;
Nixpkgs identifies 26.05 as its final release supporting Intel Macs.

The derivation extracts the signed `Nextcloud.app` from the pinned `.pkg` using
`xar`, `gzip`, and `cpio`; it does not run Apple's installer or the package's
pre-install or post-install scripts. Build the app bundle from this directory:

```sh
nix build .#nextcloud-vfs
```

The result contains `Applications/Nextcloud.app`. The `nix/` Home Manager
configuration imports this flake's module and enables it for the configured
user. Home Manager adds the app to the profile, links it under
`~/Applications/Home Manager Apps/Nextcloud.app`, and registers and enables the
Finder Sync extension with `pluginkit` during activation. The registration runs
as the user and safely skips if the app link is not present.

## Updating to a new release

From the repository root, check the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/nextcloud-vfs.json)
for the new release's `version`, `url`, and `sha256`. To inspect the relevant
fields in the API response:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/nextcloud-vfs.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, conflicts_with, deprecated, deprecation_date, deprecation_reason, deprecation_replacement_cask}'
```

Update those values in the `cask` attrset in
`custom-flakes/nextcloud-vfs/flake.nix`, along with any other metadata that
changed upstream. Keep the URL exactly aligned with the API; the current URL
uses the `version` variable. `pkgFile` is derived from the URL, so it does not
need a separate update. The Nixpkgs pin and `flake.lock` normally need no
change for a Nextcloud-only version bump.

The derivation currently expects the downloaded file to be an `xar` archive
containing `Nextcloud.pkg/Payload`, which is gzip-compressed `cpio` data with
`Applications/Nextcloud.app` inside. If the upstream package layout or payload
format changes, update the `installPhase` to match. Do not run Apple's
`installer` or the package scripts: the derivation extracts only the app, and
`dontFixup` avoids modifying its vendor signature. Keep the app bundle intact.

If the new bundle changes the Finder Sync extension path or bundle identifier,
update the corresponding path or `extensionId` default in
`home-manager-module.nix`. The module adds the app to Home Manager and runs
`pluginkit` after linking it; it skips registration when the extension is not
present. No change is needed there when the extension remains at the same path
with the same identifier.

Run these checks from the repository root after editing:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/nextcloud-vfs
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/nextcloud-vfs#nextcloud-vfs)/Applications/Nextcloud.app"
codesign --verify --deep --strict "$app"
file "$app/Contents/MacOS/Nextcloud"
nix_flake="git+file://$PWD?dir=nix"
nix flake check --all-systems --no-build --no-write-lock-file "$nix_flake"
set -o pipefail
nix eval --raw --no-write-lock-file "$nix_flake#darwinConfigurations.aarch64-darwin.config.home-manager.users.\"simeon.stix\".home.activation.nextcloudVfsFinderSync.data" | bash -n
```

On the Mac, run `nix-system-update` to activate the updated profile and
re-register Finder Sync, then check it with
`pluginkit -m -A -D -i com.nextcloud.desktopclient.FinderSyncExt`.

The app includes File Provider extensions; macOS may require launching
Nextcloud and approving its File Provider access before virtual files work.
The module does not launch the app or perform the installer’s unrelated
command-line, uninstall, or cleanup actions.