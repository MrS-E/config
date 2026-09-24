#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

FLATPAK_FILE="$SCRIPT_DIR/flatpak.txt"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists flatpak || die "flatpak not found; run 05-flatpak-runtime first"
}

help() {
  cat <<'EOF'
Install Flatpak apps listed in setup/fedora/flatpak.txt.
Idempotent: skips apps that are already installed.
EOF
}

run() {
  log "Installing Flatpak apps..."
  flatpak_install_from_manifest "$FLATPAK_FILE"
}

case "${1:-}" in
  presteps) presteps ;;
  help) help ;;
  run) run ;;
  *)
    printf 'usage: %s {presteps|help|run}\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac