#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

AUR_FILE="$SCRIPT_DIR/aur.txt"

presteps() {
  [[ -f /etc/manjaro-release ]] || die "this step requires Manjaro"
  command_exists yay || die "yay not found; run 03-yay-bootstrap first"
}

help() {
  cat <<'EOF'
Install AUR packages listed in setup/manjaro/aur.txt via yay.
Idempotent: yay -S --needed skips already-installed packages.
EOF
}

run() {
  log "Installing AUR packages..."
  aur_install_from_manifest "$AUR_FILE"
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