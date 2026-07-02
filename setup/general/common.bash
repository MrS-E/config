#!/usr/bin/env bash
# Shared platform-neutral helper library for setup steps.
#
# Sourced by step scripts via:  source "$REPO_DIR/setup/general/common.bash"
# This file is NOT executable on purpose, so the runner does not discover it as
# a step.
#
# It contains ONLY OS-agnostic primitives. Flatpak, package-manager
# (brew/dnf/pacman/rpm-ostree/yay), installer/downloader, GUI app, and
# service/shell mutation logic MUST NOT live here — keep those in the relevant
# setup/<os>/ directory or its own common.bash companion.

# Guard against double-sourcing.
[[ -n "${_SETUP_GENERAL_COMMON:-}" ]] && return 0
_SETUP_GENERAL_COMMON=1

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  local cmd="$1"
  command_exists "$cmd" || die "required command not found: $cmd"
}

# Read a manifest file, skipping blank and comment lines.
read_manifest() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -vE '^[[:space:]]*$|^[[:space:]]*#' "$file"
}

ensure_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || mkdir -p "$dir"
}

# Idempotent symlink: create dest -> src, backing up an existing non-symlink
# once with a timestamped name. If dest is already the correct symlink, no-op.
ensure_symlink() {
  local src="$1"
  local dest="$2"

  [[ -e "$src" ]] || { log "skip: source does not exist: $src"; return 0; }

  ensure_dir "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      return 0
    fi
    ln -sfn "$src" "$dest"
    log "linked: $dest -> $src"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    log "backup: $dest -> $backup"
  fi

  ln -sfn "$src" "$dest"
  log "linked: $dest -> $src"
}

# Set a git config key/value idempotently. Writes to the local repo config when
# run inside a git repo, otherwise global. Only writes when the value differs.
ensure_git_config() {
  local key="$1"
  local value="$2"
  local current
  current="$(git config "$key" 2>/dev/null || true)"
  [[ "$current" == "$value" ]] && return 0
  git config "$key" "$value"
}

# Clone a git repo if absent; never re-clone or force-update an existing one.
ensure_git_clone() {
  local url="$1"
  local dest="$2"
  [[ -d "$dest/.git" ]] && return 0
  ensure_dir "$(dirname "$dest")"
  git clone "$url" "$dest"
}

# Ensure a line is present in a text file, appending if absent. Creates the
# file (and parent dir) if needed.
ensure_line_present() {
  local file="$1"
  local line="$2"
  [[ -f "$file" ]] || { ensure_dir "$(dirname "$file")"; : > "$file"; }
  grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
}
