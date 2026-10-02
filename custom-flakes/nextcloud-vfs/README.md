# Nextcloud VFS

This standalone flake packages the macOS installer described by the [Homebrew
cask API entry](https://formulae.brew.sh/api/cask/nextcloud-vfs.json). Its
version, download URL, SHA-256, product metadata, macOS requirement, conflict,
and deprecation details are copied from that entry; the values are pinned here
rather than fetched dynamically.

The API entry currently lists version `4.0.8`, requires macOS 12 or later, and
marks the cask discontinued as of 2026-04-01, with `nextcloud` as its
replacement. Although the cask declares automatic updates, this flake remains
pinned until its metadata is updated.

The flake uses `nixpkgs-26.05-darwin` to retain an `x86_64-darwin` output;
Nixpkgs identifies 26.05 as its final release supporting Intel Macs.

Build the installer artifact from this directory:

```sh
nix build .#nextcloud-vfs
```

The result contains the original `Nextcloud-4.0.8-macOS-vfs.pkg`. Install it
with the macOS Installer:

```sh
sudo /usr/sbin/installer -pkg ./result/Nextcloud-4.0.8-macOS-vfs.pkg -target /
```

Building only fetches and places the upstream installer in the Nix store; it
does not run the installer or perform the cask's application, command-line,
uninstall, or cleanup actions.