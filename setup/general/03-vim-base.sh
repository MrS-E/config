#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  require_command mkdir
}

help() {
  cat <<'EOF'
Create OS-agnostic editor support directories such as $HOME/.vim/undo. Theme
downloads and platform-specific editor setup remain in OS-specific steps.
EOF
}

run() {
  log "Creating shared editor directories..."
  ensure_dir "$HOME/.vim/undo"
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
