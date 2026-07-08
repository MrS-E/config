#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

presteps() {
  require_command git
}

help() {
  cat <<'EOF'
Clone ZSH plugins (zsh-autosuggestions, zsh-syntax-highlighting,
zsh-autocomplete) into ~/.zsh/. Idempotent: skips existing directories.
EOF
}

run() {
  log "Installing ZSH plugins..."
  install_zsh_plugins
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