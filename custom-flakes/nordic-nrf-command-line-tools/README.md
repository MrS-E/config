# Nordic nRF Command Line Tools

This standalone flake packages version `10.24.2` from the [Homebrew cask
API](https://formulae.brew.sh/api/cask/nordic-nrf-command-line-tools.json).
The cask's DMG does **not** contain an `.app`: it contains a Nordic installer
`.pkg` and a separate SEGGER J-Link installer. The flake expands the Nordic
package and copies its CMake, `mergehex`, and `nrfjprog` payloads without
running the macOS installer. It exposes `mergehex` and `nrfjprog` in `bin/`
instead of creating Homebrew's `/usr/local/bin` symlinks.

Build from this directory with:

```sh
nix build .#nordic-nrf-command-line-tools
```

The package is added to the repository's Home Manager `home.packages`, making
both commands available in the managed user `PATH` after activation, without
shell configuration changes. It does not install a GUI app or the separate
SEGGER J-Link package. `nrfjprog` requires SEGGER J-Link to communicate with
debug probes; the Homebrew cask declares `segger-jlink` as a dependency. This
repository keeps that separately licensed package out of the profile; install
it separately after accepting SEGGER's license.

## Updating to a new release

Check the [Homebrew cask API JSON](https://formulae.brew.sh/api/cask/nordic-nrf-command-line-tools.json)
for the version, download URL, checksum, installer components, and dependency:

```sh
curl -fsSL https://formulae.brew.sh/api/cask/nordic-nrf-command-line-tools.json | jq \
  '{version, url, sha256, depends_on, artifacts}'
```

Update the matching values in `flake.nix`. Verify the new DMG layout and
component names before changing the extraction phase; the current installer
contains no `.app`, and its postinstall script only creates command symlinks.

## Verification

From the repository root, evaluate and build the package with:

```sh
nix flake check --all-systems --no-build path:./custom-flakes/nordic-nrf-command-line-tools
nix build --no-link --print-out-paths path:./custom-flakes/nordic-nrf-command-line-tools#nordic-nrf-command-line-tools
```

`mergehex --version` can be checked without hardware or J-Link. Run
`nrfjprog --version` after installing SEGGER J-Link; it loads `libjlinkarm.dylib`
even for the version command.