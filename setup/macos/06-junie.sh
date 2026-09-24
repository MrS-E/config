#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
}

help() {
  cat <<'EOF'
Install Junie CLI via the official curl installer. Idempotent: skips when junie
is already on PATH.
EOF
}

run() {
  if command_exists junie; then
    log "Junie CLI already installed ($(junie --version 2>/dev/null || true))."
    return 0
  fi

  log "Installing Junie CLI..."
  curl -fsSL https://junie.jetbrains.com/install.sh | bash

  command_exists junie || die "Junie CLI installation finished but junie is still not on PATH"
  log "Junie CLI installed ($(junie --version 2>/dev/null || true))."
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
