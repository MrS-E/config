#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  require_command curl
}

help() {
  cat <<'EOF'
Install Bun via the official installer script.
Idempotent: skips when `bun` is already on PATH.
EOF
}

run() {
  if command_exists bun; then
    log "Bun already installed ($(bun --version 2>/dev/null || true))."
    return 0
  fi
  log "Installing Bun..."
  curl -fsSL https://bun.com/install | bash
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