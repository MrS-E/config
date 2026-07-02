#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  require_command git
}

help() {
  cat <<'EOF'
Register git clean/smudge filters for this dotfiles repo: pkcs11-provider
(tokenizes/resolves SSH PKCS#11 provider paths) and scrub-apikey (redacts API
keys in junie model configs). Idempotent: filters are only rewritten when the
configured value differs.
EOF
}

run() {
  log "Configuring git filters..."

  ensure_git_config filter.pkcs11-provider.clean  "$REPO_DIR/ssh/pkcs11-filter.sh clean"
  ensure_git_config filter.pkcs11-provider.smudge "$REPO_DIR/ssh/pkcs11-filter.sh smudge"
  ensure_git_config filter.pkcs11-provider.required true

  ensure_git_config filter.scrub-apikey.clean \
    "sed -E 's/(\"apiKey\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/\\1\"REDACTED\"/'"
  ensure_git_config filter.scrub-apikey.smudge cat
  ensure_git_config filter.scrub-apikey.required true

  log "Git filters configured: pkcs11-provider, scrub-apikey"
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
