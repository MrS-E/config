#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

PACMAN_FILE="$SCRIPT_DIR/pacman.txt"

presteps() {
  [[ -f /etc/manjaro-release ]] || die "this step requires Manjaro"
  command_exists pacman || die "pacman not found"
}

help() {
  cat <<'EOF'
Install pacman packages listed in setup/manjaro/pacman.txt.
Idempotent: pacman -S --needed skips already-installed packages.
EOF
}

run() {
  log "Installing pacman packages..."
  pacman_install_from_manifest "$PACMAN_FILE"
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