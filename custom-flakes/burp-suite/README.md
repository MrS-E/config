# Burp Suite Community Edition

This standalone flake packages the macOS app from the [Homebrew cask API
entry](https://formulae.brew.sh/api/cask/burp-suite.json). The version, ARM64
download URL and SHA-256, app name, description, homepage, and cask metadata
are pinned from that JSON rather than fetched dynamically. Homebrew's
[cask definition](https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/b/burp-suite.rb)
also defines the Intel download URL and checksum, which this flake uses for
`x86_64-darwin`.

The cask currently packages Burp Suite Community Edition `2026.8`. Its
Apple-Silicon and Intel DMGs contain the `Burp Suite.app` bundle on an HFS+
disk image. The derivation uses Nixpkgs' `p7zip` to extract the image. Since
`p7zip` emits HFS+ symbolic-link targets as regular text files, the build reads
the archive's Unix mode metadata and recreates the links inside the app before
copying it into `Applications/Burp Suite.app` in the Nix output. This preserves
the vendor signature, verified for the pinned release with `codesign`. The
derivation does not run Homebrew's uninstall or cleanup actions, install the
app under `/Applications`, or configure Burp Suite. This repository's `nix/`
configuration adds it to the selected user's Home Manager profile, which
links it under `~/Applications/Home Manager Apps/Burp Suite.app`.

Build the package from this directory with:

```sh
nix build .#burp-suite
```

## Updating to a new release

Check the [Homebrew cask API entry](https://formulae.brew.sh/api/cask/burp-suite.json)
for the new version, ARM64 URL, and SHA-256:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/burp-suite.json | jq \
  '{version, url, sha256, name, desc, homepage, auto_updates, depends_on, artifacts}'
```

The API response provides the Apple-Silicon artifact. Update the Intel URL and
checksum from the matching `arch intel` entries in the linked Homebrew cask
definition as well. The archive names are derived from the version and end in
`.dmg`. If the download format or image filesystem changes, verify that
Nixpkgs' `p7zip` can extract it. If the archive's symlink metadata or app
layout changes, update the restoration logic and `cask.app`; verify the result
with `codesign --verify --deep --strict` before updating the pin. The app is
copied without fixups to preserve its vendor signature.

Validate an update from the repository root with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/burp-suite
app="$(nix build --no-link --no-write-lock-file --print-out-paths path:./custom-flakes/burp-suite#burp-suite)/Applications/Burp Suite.app"
codesign --verify --deep --strict "$app"
```