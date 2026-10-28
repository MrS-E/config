# Custom Nix Flakes Registry & Maintenance Guide

This directory contains standalone Nix flakes that package macOS desktop applications and command-line utilities consumed by the system configuration in `nix/flake.nix` (via nix-darwin and Home Manager).

---

## 1. Overview & Maintenance Philosophy

To maximize system reliability while minimizing operational toil, packages in `custom-flakes/` are stratified into three maintenance tiers based on upstream release predictability, distribution packaging formats, and maintenance overhead:

- **Tier 1 (Highest Utility — Direct / Native Source Tracking)**: Source-based tools with standard upstream repositories or PyPI packages (`adb-enhanced`, `aflplusplus`, `mbpoll`).
- **Tier 2 (High Utility — Standardized Tooling Automation via `nvfetcher`)**: Pre-compiled binary packages distributed via stable GitHub Releases, PyPI, or structured appcast feeds (`bettermouse`, `creality-print`, `nextcloud-vfs`, `proton-mail-bridge`, `prusa-slicer`, `raspberry-pi-imager`, `zotero`).
- **Tier 3 (Documented Manual Maintenance)**: Packages where upstream distribution mechanics (multi-variable hash URLs, nested Azure Blob paths, non-standard archive payloads, or custom permission restoration) make automated scrapers brittle and costly to maintain (`nordic-nrf-command-line-tools`, `texifier`, `burp-suite`, `figma`, `proton-drive`).

### Engineering Rationale for Manual Maintenance (Tier 3)

Automating updates is beneficial only when upstream release endpoints remain predictable. For Tier 3 packages, the maintenance overhead of fixing broken scrapers exceeds the cost of occasional manual bumps:

- **`nordic-nrf-command-line-tools`**: Assets are hosted on Azure Blob Storage within nested version directories (`sw/versions-10-x-x/10-24-2/...`) rather than a predictable release feed. Additionally, the DMG contains multi-component flat PKG installers (`CMAKE`, `MERGEHEX`, `NRFJPROG`) requiring custom extraction.
- **`texifier`**: Upstream download URLs require three synchronized variables: semantic version, internal build counter, and git commit hash (e.g., `Texifier_1_9_33__855__ddb6e02.dmg`). Scraping all three tokens reliably is fragile.
- **`burp-suite`**: PortSwigger distributes desktop DMGs with HFS+ filesystem symlinks and execution permissions that must be reconstructed post-extraction via `7z` metadata tables.
- **`figma`**: Packaged via desktop CDN zip distribution where release manifests undergo periodic schema changes.
- **`proton-drive`**: Distributed as vendor DMGs requiring nested `7zz` container decompression.

For all Tier 3 packages, maintainers follow the concrete runbooks below using the Homebrew Cask API as an authoritative, verified metadata proxy.

---

## 2. Complete Custom Flakes Classification Matrix

| Package Token | Description | Tier | Upstream Source Format | Update Mechanism | Supported Platforms |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `adb-enhanced` | Android testing & development CLI | **Tier 1** | PyPI source tarball | `nvfetcher` / PyPI | `aarch64-darwin`, `aarch64-linux`, `x86_64-linux` |
| `aflplusplus` | AFL++ security fuzzer | **Tier 1** | GitHub release archive | `nvfetcher` / GitHub | `aarch64-darwin`, `aarch64-linux`, `x86_64-linux` |
| `mbpoll` | ModBus RTU/TCP CLI tool | **Tier 1** | GitHub release archive | `nvfetcher` / GitHub | `aarch64-darwin`, `aarch64-linux`, `x86_64-linux` |
| `bettermouse` | Mouse customization utility | **Tier 2** | Versioned ZIP archive | `nvfetcher` / Webpage | `aarch64-darwin` |
| `creality-print` | Creality 3D printer slicer | **Tier 2** | GitHub release DMG | `nvfetcher` / GitHub | `aarch64-darwin` |
| `nextcloud-vfs` | Nextcloud Virtual Files client | **Tier 2** | GitHub release PKG | `nvfetcher` / GitHub | `aarch64-darwin` |
| `proton-mail-bridge` | Proton Mail IMAP/SMTP bridge | **Tier 2** | GitHub release DMG | `nvfetcher` / GitHub | `aarch64-darwin` |
| `prusa-slicer` | Prusa 3D printer slicer | **Tier 2** | GitHub release DMG | `nvfetcher` / GitHub | `aarch64-darwin` |
| `raspberry-pi-imager` | OS image flashing utility | **Tier 2** | GitHub release DMG | `nvfetcher` / GitHub | `aarch64-darwin` |
| `zotero` | Research & citation manager | **Tier 2** | Release DMG via HTTP redirect | `nvfetcher` / HTTP Header | `aarch64-darwin` |
| `burp-suite` | Web security penetration testing | **Tier 3** | PortSwigger CDN DMG (HFS+) | Manual (Homebrew API) | `aarch64-darwin` |
| `figma` | Interface design application | **Tier 3** | Desktop CDN ZIP | Manual (Homebrew API) | `aarch64-darwin` |
| `nordic-nrf-command-line-tools` | nRF development CLI & tools | **Tier 3** | Azure Blob DMG + PKG | Manual (Homebrew API) | `aarch64-darwin` |
| `proton-drive` | Encrypted cloud storage client | **Tier 3** | Proton CDN DMG | Manual (Homebrew API) | `aarch64-darwin` |
| `texifier` | LaTeX editor with live typesetting | **Tier 3** | Dynamic hash DMG | Manual (Homebrew API) | `aarch64-darwin` |

---

## 3. Automated Updates Workflow (Tier 1 & Tier 2)

Tier 1 and Tier 2 flakes are configured in `custom-flakes/nvfetcher.toml`. Running the updater queries upstream release endpoints, calculates SRI cryptographic hashes, and updates `_sources/generated.nix` across all target flakes.

### Running Automated Updates

To update all Tier 1 and Tier 2 packages in a single command, run the update script from the repository root:

```sh
./custom-flakes/update.sh
```

Or execute `nvfetcher` directly:

```sh
nix run nixpkgs#nvfetcher -- -c custom-flakes/nvfetcher.toml -o custom-flakes/_sources
```

### Derivation Integration & Pure Evaluation

Each automated flake imports its generated source definition dynamically:

```nix
generatedSources = if builtins.pathExists ./_sources/generated.nix
  then import ./_sources/generated.nix {
    inherit (pkgs) fetchgit fetchurl fetchFromGitHub dockerTools;
  }
  else {};
generated = generatedSources.<package-token> or null;
```

If `_sources/generated.nix` is present, the derivation consumes `generated.version` and `generated.src`. If absent, it gracefully falls back to static default attributes, preserving standalone evaluation.

---

## 4. Manual Maintenance Runbooks (Tier 3)

For Tier 3 packages, maintainers perform manual updates using the step-by-step runbooks below.

### 4.1. `nordic-nrf-command-line-tools`

- **Directory**: `custom-flakes/nordic-nrf-command-line-tools`
- **Rationale**: Hosted on Azure Blob Storage with path segments tied to major/minor versions. The DMG contains `.nRF-Command-Line-Tools-<ver>-Darwin.pkg` which expands into multiple component packages (`CMAKE`, `MERGEHEX`, `NRFJPROG`).

#### Update Steps:
1. Query the latest upstream metadata from Homebrew Cask API:
   ```sh
   curl -fsSL https://formulae.brew.sh/api/cask/nordic-nrf-command-line-tools.json | jq '{version, url, sha256}'
   ```
2. Update `version`, `url`, and `sha256` in `custom-flakes/nordic-nrf-command-line-tools/flake.nix`.
3. Verify flake evaluation and build:
   ```sh
   nix flake check --all-systems --no-build path:./custom-flakes/nordic-nrf-command-line-tools
   nix build --no-link --print-out-paths path:./custom-flakes/nordic-nrf-command-line-tools#nordic-nrf-command-line-tools
   ```

---

### 4.2. `texifier`

- **Directory**: `custom-flakes/texifier`
- **Rationale**: Download URLs require three dynamic tokens: `Texifier_<version>__<build>__<hash>.dmg`.

#### Update Steps:
1. Query the latest upstream metadata:
   ```sh
   curl -fsSL https://formulae.brew.sh/api/cask/texifier.json | jq '{version, url, sha256}'
   ```
2. Update `version` (`<version>,<build>,<hash>`), `url`, and `sha256` in `custom-flakes/texifier/flake.nix`.
3. Verify evaluation, build, and code signature:
   ```sh
   nix flake check --all-systems --no-build path:./custom-flakes/texifier
   app="$(nix build --no-link --print-out-paths path:./custom-flakes/texifier#texifier)/Applications/Texifier.app"
   codesign --verify --deep --strict "$app"
   ```

---

### 4.3. `burp-suite`

- **Directory**: `custom-flakes/burp-suite`
- **Rationale**: PortSwigger CDN DMG contains HFS+ symbolic links and Unix permissions that require extraction via `7z` metadata parsing and permission reapplication.

#### Update Steps:
1. Query the latest upstream metadata:
   ```sh
   curl -fsSL https://formulae.brew.sh/api/cask/burp-suite.json | jq '{version, url, sha256}'
   ```
2. Update `cask.version`, `cask.url`, and `cask.sha256` in `custom-flakes/burp-suite/flake.nix`.
3. Verify evaluation, build, and code signature:
   ```sh
   nix flake check --all-systems --no-build path:./custom-flakes/burp-suite
   app="$(nix build --no-link --print-out-paths path:./custom-flakes/burp-suite#burp-suite)/Applications/Burp Suite.app"
   codesign --verify --deep --strict "$app"
   ```

---

### 4.4. `figma`

- **Directory**: `custom-flakes/figma`
- **Rationale**: Packaged via desktop CDN zip archives with versioned paths per architecture.

#### Update Steps:
1. Query the latest upstream metadata:
   ```sh
   curl -fsSL https://formulae.brew.sh/api/cask/figma.json | jq '{version, url, sha256}'
   ```
2. Update `version`, `archives.aarch64-darwin.url`, and `archives.aarch64-darwin.sha256` in `custom-flakes/figma/flake.nix`.
3. Verify evaluation, build, and code signature:
   ```sh
   nix flake check --all-systems --no-build path:./custom-flakes/figma
   app="$(nix build --no-link --print-out-paths path:./custom-flakes/figma#figma)/Applications/Figma.app"
   codesign --verify --deep --strict "$app"
   ```

---

### 4.5. `proton-drive`

- **Directory**: `custom-flakes/proton-drive`
- **Rationale**: Distributed as a vendor DMG requiring nested `7zz` extraction.

#### Update Steps:
1. Query the latest upstream metadata:
   ```sh
   curl -fsSL https://formulae.brew.sh/api/cask/proton-drive.json | jq '{version, url, sha256}'
   ```
2. Update `version`, `url`, and `sha256` in `custom-flakes/proton-drive/flake.nix`.
3. Verify evaluation, build, and code signature:
   ```sh
   nix flake check --all-systems --no-build path:./custom-flakes/proton-drive
   app="$(nix build --no-link --print-out-paths path:./custom-flakes/proton-drive#proton-drive)/Applications/Proton Drive.app"
   codesign --verify --deep --strict "$app"
   ```

---

## 5. End-to-End Verification & Integrity Procedures

To maintain repository stability and prevent runtime macOS quarantine / Gatekeeper errors, all modified flakes must undergo the following standard verification suite:

### 1. Schema & Evaluation Check
Run pure flake checks without triggering network builds:
```sh
for flake in custom-flakes/*; do
  if [ -f "$flake/flake.nix" ]; then
    nix flake check --all-systems --no-build "path:$flake"
  fi
done
```

### 2. Output Build Validation
Test build individual packages to verify archive decompression and folder layout:
```sh
nix build --no-link --print-out-paths path:./custom-flakes/<package-token>#<package-token>
```

### 3. macOS Code Signature Verification
Verify that binary bundles preserve valid vendor cryptographic signatures:
```sh
app_path="$(nix build --no-link --print-out-paths path:./custom-flakes/<package-token>#<package-token>)/Applications/<App>.app"
codesign --verify --deep --strict "$app_path"
```

### 4. Root Configuration Integrity
Confirm that the root system flake evaluates cleanly against the updated custom flake inputs:
```sh
nix flake check --no-build path:./nix
nix flake check --no-build path:./nix-darwin
```
