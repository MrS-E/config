#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

BREWFILE="$SCRIPT_DIR/Brewfile"

presteps() {
  require_command brew
  [[ -f "$BREWFILE" ]] || die "Brewfile not found: $BREWFILE"
}

help() {
  cat <<'EOF'
Install Homebrew packages from setup/macos/Brewfile via `brew bundle`.
Idempotent: brew bundle is a no-op for already-installed packages.
EOF
}

run() {
  log "Installing Homebrew packages from Brewfile..."
  brew bundle --file="$BREWFILE"
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