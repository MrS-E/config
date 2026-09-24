#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

THEME_DIR="$HOME/.vim/pack/themes/start/dracula"

presteps() {
  require_command git
}

help() {
  cat <<'EOF'
Clone the Dracula vim theme into ~/.vim/pack/themes/start/dracula.
Idempotent: skips when the theme directory already exists.
EOF
}

run() {
  if [[ -d "$THEME_DIR" ]]; then
    log "Dracula vim theme already installed."
    return 0
  fi
  log "Installing Dracula vim theme..."
  ensure_dir "$(dirname "$THEME_DIR")"
  git clone https://github.com/dracula/vim.git "$THEME_DIR"
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