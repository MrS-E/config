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
Install Junie CLI via the official installer script.
Idempotent: skips when `junie` is already on PATH.
EOF
}

run() {
  if command_exists junie; then
    log "Junie already installed."
    return 0
  fi
  log "Installing Junie..."
  curl -fsSL https://junie.jetbrains.com/install.sh | bash
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