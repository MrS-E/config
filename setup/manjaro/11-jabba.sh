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
Install Jabba (Java Version Manager) via the official installer.
Idempotent: skips when ~/.jabba already exists.
EOF
}

run() {
  if [[ -d "$HOME/.jabba" ]]; then
    log "Jabba already installed."
    return 0
  fi
  log "Installing Jabba..."
  curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
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