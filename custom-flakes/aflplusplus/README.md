# AFL++

This standalone flake builds the AFL++ `5.03c` source archive listed in the
[Homebrew formula API](https://formulae.brew.sh/api/formula/afl++.json). The
archive URL and SHA-256 are pinned in `flake.nix`; the archive checksum was
verified against the downloaded release. The Homebrew bottles are not used:
their metadata points into Homebrew Cellar paths, while this package installs
into the Nix store.

Build the package from this directory with:

```sh
nix build .#aflplusplus
```

The package builds the upstream source and installs its command-line tools
under `bin/`. The repository's `nix/` flake includes it in Home Manager's
`home.packages`, so tools such as `afl-fuzz` and `afl-clang-fast` are available
in the managed user `PATH` after activation without editing `zshrc`.

## Updating to a new release

Check the [Homebrew formula API JSON](https://formulae.brew.sh/api/formula/afl++.json)
for the current source URL and checksum:

```sh
curl -fsSL https://formulae.brew.sh/api/formula/afl++.json | jq \
  '{versions, urls, dependencies, build_dependencies}'
```

Update `version`, the source URL, and the SHA-256 in `flake.nix`. The macOS
build skips upstream in-build tests that require changing system settings as
root, matching the Homebrew formula. AFL++ currently calls an API introduced
in macOS 14.4 without a runtime availability guard, so the Darwin package
targets macOS 14.4 or later. The Homebrew bottle should not be used as a
substitute for the source archive because it is installed under a
Homebrew-specific Cellar prefix.

## Verification

From the repository root, check flake evaluation and build the package with:

```sh
nix flake check --all-systems --no-build --no-write-lock-file path:./custom-flakes/aflplusplus
nix build --no-link --no-write-lock-file path:./custom-flakes/aflplusplus#aflplusplus
```