#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

JETBRAINS_VERSION="3.0.1.59888"
BASE_DIR="$HOME/.config/jetbrains"
ARCHIVE="$BASE_DIR/jetbrains-toolbox-$JETBRAINS_VERSION.tar.gz"
UNPACKED="$BASE_DIR/jetbrains-toolbox-$JETBRAINS_VERSION"
BIN="$UNPACKED/bin/jetbrains-toolbox"

presteps() {
  require_command wget
  require_command tar
}

help() {
  cat <<'EOF'
Download and extract JetBrains Toolbox. Does NOT launch it.
Idempotent: skips when the toolbox binary already exists.
EOF
}

run() {
  if [[ -x "$BIN" ]]; then
    log "JetBrains Toolbox already installed at $BIN"
    return 0
  fi

  log "Downloading JetBrains Toolbox $JETBRAINS_VERSION..."
  ensure_dir "$BASE_DIR"
  wget -q -O "$ARCHIVE" "https://download.jetbrains.com/toolbox/jetbrains-toolbox-$JETBRAINS_VERSION.tar.gz"
  tar -xzf "$ARCHIVE" -C "$BASE_DIR"
  log "JetBrains Toolbox extracted to $UNPACKED"
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