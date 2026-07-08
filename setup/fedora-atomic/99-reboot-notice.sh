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
Print a reminder to reboot if rpm-ostree layered packages were requested.
Always runs (informational only).
EOF
}

run() {
  log ""
  log "Fedora Atomic setup complete."
  log ""
  log "If host packages were layered via rpm-ostree, reboot to activate them:"
  log "  systemctl reboot"
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