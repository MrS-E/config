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
Enable and start ClamAV freshclam service.
Idempotent: systemctl enable --now is safe on already-running services.
EOF
}

run() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^clamav-freshclam\.service'; then
    log "Enabling ClamAV freshclam..."
    sudo systemctl enable --now clamav-freshclam.service 2>/dev/null || log "warn: ClamAV service setup failed (may be expected in containers)"
  else
    log "ClamAV freshclam service not found; skipping."
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