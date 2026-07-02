#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
}

help() {
  cat <<'EOF'
Ensure Flatpak is installed and the Flathub remote exists.
Idempotent: skips when Flatpak and Flathub are already present.
EOF
}

run() {
  log "Setting up Flatpak remote..."
  ensure_flatpak_remote
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