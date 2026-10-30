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
  require_command awk
  require_command sed
}

help() {
  cat <<'EOF'
Register git clean/smudge filters for this dotfiles repo: pkcs11-provider
(tokenizes/resolves SSH PKCS#11 provider paths), git-email (selects the email
from gitconfig.profiles using gitconfig.vars), gitconfig-vars (redacts the
selected profile in the staged selector), scrub-apikey (redacts API keys in
Junie model configs), and Junie JSON filters (require Python 3, track selected
settings, and keep MCP enabled values local). Idempotent: filters are only
rewritten when the configured value differs.
EOF
}

prepare_gitconfig_vars() {
  local file="$REPO_DIR/gitconfig.vars" tmpfile
  if [[ ! -f "$file" ]]; then
    printf '[git]\nprofile = "PRIVATE"\n' > "$file"
    log "Created gitconfig.vars with the default PRIVATE profile."
    return
  fi

  tmpfile="$(mktemp "$REPO_DIR/.gitconfig-vars-filter.XXXXXX")"
  if "$REPO_DIR/gitconfig-filter.sh" vars-smudge < "$file" > "$tmpfile"; then
    if cmp -s "$tmpfile" "$file"; then
      rm -f "$tmpfile"
    else
      mv "$tmpfile" "$file"
    fi
  else
    rm -f "$tmpfile"
    return 1
  fi
}

refresh_gitconfig() {
  local file="gitconfig" tmpfile
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git ls-files --error-unmatch -- "$file" >/dev/null 2>&1 || return 0

  git update-index --refresh -- "$file" >/dev/null 2>&1 || true
  if git diff --quiet -- "$file"; then
    tmpfile="$(mktemp "$REPO_DIR/.gitconfig-filter.XXXXXX")"
    cp -p "$REPO_DIR/$file" "$tmpfile"
    if git show ":$file" | "$REPO_DIR/gitconfig-filter.sh" smudge > "$tmpfile"; then
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
}

run() {
  log "Configuring git filters..."

  prepare_gitconfig_vars
  "$REPO_DIR/gitconfig-filter.sh" smudge </dev/null >/dev/null

  ensure_git_config filter.git-email.clean  "./gitconfig-filter.sh clean"
  ensure_git_config filter.git-email.smudge "./gitconfig-filter.sh smudge"
  ensure_git_config filter.git-email.required true

  ensure_git_config filter.gitconfig-vars.clean  "./gitconfig-filter.sh vars-clean"
  ensure_git_config filter.gitconfig-vars.smudge "./gitconfig-filter.sh vars-smudge"
  ensure_git_config filter.gitconfig-vars.required true

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
    git ls-files --error-unmatch -- gitconfig.vars >/dev/null 2>&1; then
    git update-index --refresh -- gitconfig.vars >/dev/null 2>&1 || true
  fi

  ensure_git_config filter.pkcs11-provider.clean  "ssh/pkcs11-filter.sh clean"
  ensure_git_config filter.pkcs11-provider.smudge "ssh/pkcs11-filter.sh smudge"
  ensure_git_config filter.pkcs11-provider.required true

  ensure_git_config filter.scrub-apikey.clean \
    "sed -E 's/(\"apiKey\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/\\1\"REDACTED\"/'"
  ensure_git_config filter.scrub-apikey.smudge cat
  ensure_git_config filter.scrub-apikey.required true

  ensure_git_config filter.junie-settings.clean \
    "python3 junie/junie-json-filter.py clean-settings"
  ensure_git_config filter.junie-settings.smudge \
    "python3 junie/junie-json-filter.py smudge-settings %f"
  ensure_git_config filter.junie-settings.required true

  ensure_git_config filter.junie-mcp.clean \
    "python3 junie/junie-json-filter.py clean-mcp"
  ensure_git_config filter.junie-mcp.smudge \
    "python3 junie/junie-json-filter.py smudge-mcp %f"
  ensure_git_config filter.junie-mcp.required true

  refresh_gitconfig

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

  log "Git filters configured: git-email, gitconfig-vars, pkcs11-provider, scrub-apikey, junie-settings, junie-mcp"
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
