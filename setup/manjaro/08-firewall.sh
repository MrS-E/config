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
Enable nftables firewall and ufw.
Idempotent: systemctl enable --now and ufw --force enable are safe to re-run.
EOF
}

run() {
  if command_exists pacman && pacman -Q nftables >/dev/null 2>&1; then
    log "Enabling nftables..."
    sudo systemctl enable --now nftables 2>/dev/null || log "warn: nftables setup failed (may be expected in containers)"
  fi

  if command_exists ufw; then
    log "Enabling ufw..."
    sudo ufw --force enable 2>/dev/null || log "warn: ufw setup failed (may be expected in containers)"
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