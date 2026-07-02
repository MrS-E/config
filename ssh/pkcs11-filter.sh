#!/usr/bin/env sh
set -eu

# Git clean/smudge filter for PKCS#11 provider paths in SSH config.
#
# clean:  replace real provider paths with @TOKEN@ placeholders (portable commits)
# smudge: replace @TOKEN@ with the current platform's real paths (live working tree)
#
# Provider paths are defined in providers.mac and providers.fedora (never hosts).
# Host stanzas stay in config.d/* as the single source of truth.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Emit sed substitution rules (path -> @VAR@) from all platform provider files.
# Used by clean to tokenize any known platform path.
clean_rules() {
  {
    [ -f "$SCRIPT_DIR/providers.mac" ] && cat "$SCRIPT_DIR/providers.mac"
    [ -f "$SCRIPT_DIR/providers.fedora" ] && cat "$SCRIPT_DIR/providers.fedora"
  } 2>/dev/null | grep -v '^#' | grep -v '^$' | while IFS='=' read -r var path; do
    [ -n "$var" ] && [ -n "$path" ] && printf 's|%s|@%s@|g\n' "$path" "$var"
  done
}

cmd="${1:-}"

case "$cmd" in
  clean)
    tmpfile="$(mktemp)"
    clean_rules > "$tmpfile"
    if [ -s "$tmpfile" ]; then
      sed -f "$tmpfile"
    else
      cat
    fi
    rm -f "$tmpfile"
    ;;
  smudge)
    pf=""
    case "$(uname -s)" in
      Darwin) pf="$SCRIPT_DIR/providers.mac" ;;
      Linux)  pf="$SCRIPT_DIR/providers.fedora" ;;
    esac
    if [ -z "$pf" ] || [ ! -f "$pf" ]; then
      # Fallback if providers file not yet checked out (fresh clone race).
      case "$(uname -s)" in
        Darwin)
          YKCS11="/opt/homebrew/lib/libykcs11.dylib"
          OPENSC="/opt/homebrew/lib/opensc-pkcs11.so"
          ;;
        *)
          cat
          exit 0
          ;;
      esac
    else
      # shellcheck disable=SC1090
      . "$pf"
    fi
    sed -e "s|@YKCS11@|$YKCS11|g" -e "s|@OPENSC@|$OPENSC|g"
    ;;
  *)
    echo "usage: $0 {clean|smudge}" >&2
    exit 1
    ;;
esac
