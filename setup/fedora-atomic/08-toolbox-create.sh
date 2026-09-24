#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

TOOLBOXES_FILE="$SCRIPT_DIR/toolboxes.txt"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists toolbox || die "toolbox not found"
}

help() {
  cat <<'EOF'
Create toolboxes listed in setup/fedora-atomic/toolboxes.txt.
Idempotent: skips toolboxes that already exist.
EOF
}

run() {
  log "Creating toolboxes..."
  create_toolboxes "$TOOLBOXES_FILE"
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