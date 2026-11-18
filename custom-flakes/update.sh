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

echo "==> Distributing package-specific generated sources to individual flakes..."
python3 "$SCRIPT_DIR/distribute-sources.py" "${AUTOMATED_FLAKES[@]}"

echo "==> Custom flakes update completed successfully."
