#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="$SCRIPT_DIR/gitconfig.profiles"
VARS_FILE="$SCRIPT_DIR/gitconfig.vars"

resolve_email() {
  if [ ! -f "$PROFILE_FILE" ]; then
    printf 'gitconfig-filter: missing profile map: %s\n' "$PROFILE_FILE" >&2
    return 1
  fi

  profile="$(vars_profile)" || return 1

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

read_profile() {
  if [ ! -f "$1" ]; then
    return 1
  fi

  awk '
    function trim(text) {
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+$/, "", text)
      return text
    }

    {
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      line = trim(line)
      if (substr(line, 1, 1) == "[" && substr(line, length(line), 1) == "]") {
        section = trim(substr(line, 2, length(line) - 2))
        next
      }
      equals = index(line, "=")
      if (equals == 0) next
      key = trim(substr(line, 1, equals - 1))
      if (section == "git" && key == "profile") {
        count++
        value = trim(substr(line, equals + 1))
      }
    }

    END {
      if (count != 1 || value !~ /^"[A-Z0-9_-]+"$/) exit 1
      print substr(value, 2, length(value) - 2)
    }
  ' "$1"
}

profile_cache_file() {
  git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || git -C "$SCRIPT_DIR" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  printf '%s/gitconfig-vars-profile\n' "$git_dir"
}

read_cached_profile() {
  cache_file="$(profile_cache_file)" || return 1
  [ -f "$cache_file" ] || return 1
  IFS= read -r cached_profile < "$cache_file" || return 1
  case "$cached_profile" in
    ''|REDACTED|*[!A-Z0-9_-]*) return 1 ;;
  esac
  printf '%s\n' "$cached_profile"
}

write_cached_profile() {
  case "${1:-}" in
    ''|REDACTED|*[!A-Z0-9_-]*) return 0 ;;
  esac
  cache_file="$(profile_cache_file)" || return 0
  if cached_profile="$(read_cached_profile)" && [ "$cached_profile" = "$1" ]; then
    return 0
  fi
  cache_tmpfile="$(mktemp "$cache_file.XXXXXX" 2>/dev/null)" || return 0
  if printf '%s\n' "$1" > "$cache_tmpfile"; then
    mv "$cache_tmpfile" "$cache_file"
  else
    rm -f "$cache_tmpfile"
  fi
}

vars_profile() {
  if [ ! -f "$VARS_FILE" ]; then
    if profile="$(read_cached_profile)"; then
      printf '%s\n' "$profile"
    else
      printf 'PRIVATE\n'
    fi
    return 0
  fi

  profile="$(read_profile "$VARS_FILE")" || {
    printf 'gitconfig-filter: expected one TOML [git].profile string in %s\n' "$VARS_FILE" >&2
    return 1
  }

  case "$profile" in
    REDACTED)
      if ! profile="$(read_cached_profile)"; then
        profile=PRIVATE
      fi
      ;;
    ''|*[!A-Z0-9_-]*)
      printf 'gitconfig-filter: invalid profile: %s\n' "$profile" >&2
      return 1
      ;;
    *)
      write_cached_profile "$profile"
      ;;
  esac

  printf '%s\n' "$profile"
}

rewrite_vars_profile() {
  awk -v profile="$1" '
    function trim(text) {
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+$/, "", text)
      return text
    }

    {
      lines[NR] = $0
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      line = trim(line)
      if (substr(line, 1, 1) == "[" && substr(line, length(line), 1) == "]") {
        section = trim(substr(line, 2, length(line) - 2))
        next
      }
      equals = index(line, "=")
      if (equals == 0) next
      key = trim(substr(line, 1, equals - 1))
      if (section != "git" || key != "profile") next
      count++
      value = trim(substr(line, equals + 1))
      if (value !~ /^"[A-Z0-9_-]+"$/) invalid = 1
      lines[NR] = "profile = \"" profile "\""
    }

    END {
      if (count != 1 || invalid) exit 1
      for (line = 1; line <= NR; line++) print lines[line]
    }
  '
}

case "${1:-}" in
  clean)
    sed -E 's/^([[:space:]]*email[[:space:]]*=[[:space:]]*).*/\1@GIT_EMAIL@/'
    ;;
  smudge)
    email="$(resolve_email)" || exit 1
    sed "s|@GIT_EMAIL@|$email|g"
    ;;
  vars-clean)
    clean_tmpfile="$(mktemp)"
    cat > "$clean_tmpfile"
    profile="$(read_profile "$clean_tmpfile")" || {
      rm -f "$clean_tmpfile"
      printf 'gitconfig-filter: expected one TOML [git].profile string in %s\n' "$VARS_FILE" >&2
      exit 1
    }
    write_cached_profile "$profile"
    rewrite_vars_profile REDACTED < "$clean_tmpfile" || {
      rm -f "$clean_tmpfile"
      printf 'gitconfig-filter: expected one TOML [git].profile string in %s\n' "$VARS_FILE" >&2
      exit 1
    }
    rm -f "$clean_tmpfile"
    ;;
  vars-smudge)
    profile="$(vars_profile)" || exit 1
    rewrite_vars_profile "$profile"
    ;;
  *)
    printf 'usage: %s {clean|smudge|vars-clean|vars-smudge}\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac