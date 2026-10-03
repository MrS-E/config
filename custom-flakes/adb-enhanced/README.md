# adb-enhanced

This standalone flake packages [`adb-enhanced`](https://github.com/ashishb/adb-enhanced)
`2.12.0` from its PyPI source distribution. It uses Python 3.12 and pins the
source archive's SHA-256 in `flake.nix`. The package includes the Python runtime
dependencies and adds Nixpkgs' Android platform tools to `adbe`'s `PATH`.
The standalone flake pins Nixpkgs 26.05 to retain `x86_64-darwin` support; this
is the last Nixpkgs release supporting Intel macOS.

Build the package from this directory with:

```sh
nix build .#adb-enhanced
```

The `adbe` command is also added to the repository's Home Manager
`home.packages`, making it available in the managed user `PATH` after
activation.

## Updating to a new release

Check the [PyPI JSON API](https://pypi.org/pypi/adb-enhanced/json) for the
current version and source distribution SHA-256. Update `version` and the
checksum in `flake.nix`, then confirm that the Nixpkgs Python 3.12 package set
provides the upstream runtime dependencies.

## Verification

From the repository root, evaluate all supported systems and build the package
with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/adb-enhanced
nix build --no-link --no-write-lock-file path:./custom-flakes/adb-enhanced#adb-enhanced
```