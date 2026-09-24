#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

RPM_OSTREE_FILE="$SCRIPT_DIR/rpm-ostree.txt"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists rpm-ostree || die "rpm-ostree not found"
}

help() {
  cat <<'EOF'
Layer host packages from setup/fedora-atomic/rpm-ostree.txt via rpm-ostree.
Idempotent: rpm-ostree install is a no-op for already-layered packages.
EOF
}

run() {
  layer_host_packages "$RPM_OSTREE_FILE"
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