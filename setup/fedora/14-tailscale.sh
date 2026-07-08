#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
}

help() {
  cat <<'EOF'
Enable and start Tailscale, and set the current user as operator.
Idempotent: systemctl enable --now is safe on already-running services;
tailscale set --operator is safe to re-run.
EOF
}

run() {
  log "Enabling Tailscale..."
  sudo systemctl enable --now tailscaled 2>/dev/null || log "warn: tailscaled service setup failed (may be expected in containers)"
  sudo tailscale set --operator="$USER" 2>/dev/null || log "warn: tailscale operator setup failed (may be expected in containers)"
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