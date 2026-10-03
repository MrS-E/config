# mbpoll

This standalone flake builds `mbpoll` `1.5.4` from the source archive listed in
the [Homebrew formula API](https://formulae.brew.sh/api/formula/mbpoll.json).
The source URL and SHA-256 are pinned in `flake.nix`. It builds with CMake and
Nixpkgs `libmodbus`; it does not use Homebrew's bottles.

Build the package from this directory with:

```sh
nix build .#mbpoll
```

The flake applies the upstream `limits.h` fix also used by the Homebrew
formula. The repository's `nix/` flake adds `mbpoll` to Home Manager's
`home.packages`, making the command available in the managed user `PATH` after
activation without editing `zshrc`.

## Updating to a new release

Check the [Homebrew formula API JSON](https://formulae.brew.sh/api/formula/mbpoll.json)
for the current source URL, checksum, and dependencies:

```sh
curl -fsSL https://formulae.brew.sh/api/formula/mbpoll.json | jq \
  '{versions, urls, dependencies, build_dependencies, license}'
```

Update `version`, the source URL, and its SHA-256 in `flake.nix`. Check the
Homebrew formula for additional patches or build steps required by new releases.

## Verification

From the repository root, evaluate all supported systems and build the package
with:

```sh
nix flake check --all-systems --no-build path:./custom-flakes/mbpoll
nix build --no-link --print-out-paths path:./custom-flakes/mbpoll#mbpoll
```