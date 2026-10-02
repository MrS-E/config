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

The app includes File Provider extensions; macOS may require launching
Nextcloud and approving its File Provider access before virtual files work.
The module does not launch the app or perform the installer’s unrelated
command-line, uninstall, or cleanup actions.