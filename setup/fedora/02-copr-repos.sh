#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

COPR_FILE="$SCRIPT_DIR/copr.txt"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists dnf || die "dnf not found"
}

help() {
  cat <<'EOF'
Enable COPR repositories listed in setup/fedora/copr.txt.
Idempotent: skips repos that are already enabled.
EOF
}

run() {
  log "Enabling COPR repositories..."
  enable_copr_from_manifest "$COPR_FILE"
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