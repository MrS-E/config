#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  require_command git
  require_command mktemp
  require_command cmp
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

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
      git update-index --refresh -- "$file" >/dev/null 2>&1 || true
      if git diff --quiet -- "$file"; then
        tmpfile="$(mktemp "$REPO_DIR/.pkcs11-filter.XXXXXX")"
        cp -p "$REPO_DIR/$file" "$tmpfile"
        if git show ":$file" | "$REPO_DIR/ssh/pkcs11-filter.sh" smudge > "$tmpfile"; then
          if cmp -s "$tmpfile" "$REPO_DIR/$file"; then
            rm -f "$tmpfile"
          else
            mv "$tmpfile" "$REPO_DIR/$file"
            git update-index --refresh -- "$file" >/dev/null 2>&1 || true
          fi
        else
          rm -f "$tmpfile"
          return 1
        fi
      else
        log "skip: modified git-filtered file: $file"
      fi
    done < <(git ls-files -z -- 'ssh/config.d/*')
  fi

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
