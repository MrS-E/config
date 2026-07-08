#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  return 0
}

help() {
  cat <<'EOF'
Print a note about Cisco AnyConnect VPN setup. Informational only.
EOF
}

run() {
  log ""
  log "=== Cisco AnyConnect VPN ==="
  log "Cisco AnyConnect is not installed automatically."
  log "Download it from your organization's VPN portal and install manually."
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