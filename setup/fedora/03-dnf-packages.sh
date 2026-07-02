#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

DNF_FILE="$SCRIPT_DIR/dnf.txt"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists dnf || die "dnf not found"
}

help() {
  cat <<'EOF'
Install dnf packages listed in setup/fedora/dnf.txt.
Idempotent: dnf install skips already-installed packages.
EOF
}

run() {
  log "Installing dnf packages..."
  dnf_install_from_manifest "$DNF_FILE"
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