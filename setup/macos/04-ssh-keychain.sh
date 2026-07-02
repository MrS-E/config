#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
  require_command ssh-add
}

help() {
  cat <<'EOF'
Add private SSH keys (~/.ssh/*, mode 0600, excluding .pub/known_hosts/config)
to the Apple keychain via `ssh-add --apple-use-keychain`. Idempotent: keys
already in the agent are not re-added (ssh-add handles this natively).
EOF
}

run() {
  local ssh_dir="$HOME/.ssh"
  [[ -d "$ssh_dir" ]] || { log "no ~/.ssh directory; skipping."; return 0; }

  local added=0
  while IFS= read -r -d '' key; do
    case "$(basename "$key")" in
      *.pub|known_hosts|config) continue ;;
    esac
    log "Adding SSH key to Apple keychain: $key"
    ssh-add --apple-use-keychain "$key" >/dev/null 2>&1 || true
    added=$((added + 1))
  done < <(find "$ssh_dir" -type f -perm 600 -print0 2>/dev/null)

  log "Processed $added SSH key(s)."
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