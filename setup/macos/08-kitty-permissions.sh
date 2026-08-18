#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

FULL_DISK_ACCESS_URL="x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
LOCAL_NETWORK_URL="x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork"

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
  require_command open
}

help() {
  cat <<'EOF'
Open macOS Privacy & Security settings so Kitty can be granted Full Disk Access
and Local Network access. macOS requires these permissions to be enabled by the
user; the step cannot grant them automatically.
EOF
}

run() {
  log "Opening Full Disk Access settings for Kitty..."
  open "$FULL_DISK_ACCESS_URL"

  log "Opening Local Network settings for Kitty..."
  open "$LOCAL_NETWORK_URL"

  log "In Full Disk Access, add /Applications/kitty.app and enable it."
  log "In Local Network, enable Kitty if it is listed."
  log "Restart Kitty for the changes to take effect."
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
