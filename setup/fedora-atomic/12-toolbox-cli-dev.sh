#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists toolbox || die "toolbox not found"
}

help() {
  cat <<'EOF'
Install Jabba inside the cli-dev toolbox.
Idempotent: skips when Jabba is already installed.
EOF
}

run() {
  log "Installing Jabba in cli-dev toolbox..."

  tb_run cli-dev '
    if [ ! -d "$HOME/.jabba" ]; then
      curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
    fi
  '
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