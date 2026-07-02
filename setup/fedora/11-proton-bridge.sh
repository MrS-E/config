#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

PROTON_RPM="protonmail-bridge-3.13.0-1.x86_64.rpm"
PROTON_URL="https://proton.me/download/bridge/$PROTON_RPM"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  require_command wget
  require_command dnf
}

help() {
  cat <<'EOF'
Download and install Proton Mail Bridge RPM.
Idempotent: skips when the package is already installed (checked via rpm -q).
EOF
}

run() {
  if rpm -q protonmail-bridge >/dev/null 2>&1; then
    log "Proton Mail Bridge already installed."
    return 0
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  log "Downloading Proton Mail Bridge..."
  wget -q -P "$tmpdir" "$PROTON_URL"
  sudo dnf install -y "$tmpdir/$PROTON_RPM"
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