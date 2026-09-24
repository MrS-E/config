#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  [[ -f /etc/manjaro-release ]] || die "this step requires Manjaro"
}

help() {
  cat <<'EOF'
Enable and start CUPS printing service.
Idempotent: systemctl enable --now is safe on already-running services.
EOF
}

run() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^cups\.service'; then
    log "Enabling CUPS..."
    sudo systemctl enable --now cups.service 2>/dev/null || log "warn: CUPS service setup failed (may be expected in containers)"
  else
    log "CUPS service not found; skipping."
  fi
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