#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Running nvfetcher to update automated custom flake sources..."
nix run nixpkgs#nvfetcher -- -c nvfetcher.toml -o _sources "$@"

AUTOMATED_FLAKES=(
  "adb-enhanced"
  "aflplusplus"
  "bettermouse"
  "creality-print"
  "mbpoll"
  "nextcloud-vfs"
  "proton-mail-bridge"
  "prusa-slicer"
  "raspberry-pi-imager"
  "zotero"
)

echo "==> Synchronizing generated sources to individual flake directories..."
for flake in "${AUTOMATED_FLAKES[@]}"; do
  if [ -d "$flake" ]; then
    mkdir -p "$flake/_sources"
    cp -f _sources/generated.nix "$flake/_sources/generated.nix"
    cp -f _sources/generated.json "$flake/_sources/generated.json"
  fi
done

echo "==> Custom flakes update completed successfully."
