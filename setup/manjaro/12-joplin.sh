#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

JOPLIN_URL="https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh"

presteps() {
  require_command wget
}

help() {
  cat <<'EOF'
Install Joplin via the official install/update script.
Idempotent: skips when `joplin` is already on PATH.
EOF
}

run() {
  if command_exists joplin; then
    log "Joplin already installed ($(joplin --version 2>/dev/null || true))."
    return 0
  fi
  log "Installing Joplin..."
  wget -O - "$JOPLIN_URL" | bash
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