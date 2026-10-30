#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="$SCRIPT_DIR/gitconfig.profiles"
VARS_FILE="$SCRIPT_DIR/gitconfig.vars"

resolve_email() {
  if [ ! -f "$VARS_FILE" ]; then
    printf 'gitconfig-filter: missing selector file: %s\n' "$VARS_FILE" >&2
    return 1
  fi
  if [ ! -f "$PROFILE_FILE" ]; then
    printf 'gitconfig-filter: missing profile map: %s\n' "$PROFILE_FILE" >&2
    return 1
  fi

  profile="$(awk -F= '
    $1 == "GIT_PROFILE" {
      count++
      value = substr($0, index($0, "=") + 1)
    }
    END {
      if (count != 1) exit 1
      print value
    }
  ' "$VARS_FILE")" || {
    printf 'gitconfig-filter: expected one GIT_PROFILE entry in %s\n' "$VARS_FILE" >&2
    return 1
  }

  case "$profile" in
    ''|*[!A-Z0-9_-]*)
      printf 'gitconfig-filter: invalid GIT_PROFILE: %s\n' "$profile" >&2
      return 1
      ;;
  esac

  email="$(awk -F= -v name="$profile" '
    $1 == name {
      count++
      value = substr($0, index($0, "=") + 1)
    }
    END {
      if (count != 1 || value == "") exit 1
      print value
    }
  ' "$PROFILE_FILE")" || {
    printf 'gitconfig-filter: unknown or ambiguous profile: %s\n' "$profile" >&2
    return 1
  }

  case "$email" in
    *@*) printf '%s\n' "$email" ;;
    *)
      printf 'gitconfig-filter: invalid email for profile %s\n' "$profile" >&2
      return 1
      ;;
  esac
}

case "${1:-}" in
  clean)
    sed -E 's/^([[:space:]]*email[[:space:]]*=[[:space:]]*).*/\1@GIT_EMAIL@/'
    ;;
  smudge)
    email="$(resolve_email)" || exit 1
    sed "s|@GIT_EMAIL@|$email|g"
    ;;
  *)
    printf 'usage: %s {clean|smudge}\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac