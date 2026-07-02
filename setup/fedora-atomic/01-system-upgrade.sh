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
  command_exists rpm-ostree || die "rpm-ostree not found; this does not look like Fedora Atomic"
}

help() {
  cat <<'EOF'
Upgrade the system via `sudo rpm-ostree upgrade`.
Idempotent: safe to run repeatedly.
EOF
}

run() {
  log "Upgrading system via rpm-ostree..."
  sudo rpm-ostree upgrade
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