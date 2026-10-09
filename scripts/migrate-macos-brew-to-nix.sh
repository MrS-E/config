#!/usr/bin/env bash
set -euo pipefail

MIGRATION_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_REPO_DIR="$(cd "$MIGRATION_SCRIPT_DIR/.." && pwd)"
HOMEBREW_UNINSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"

BREW_BIN=""
CURL_BIN=""
BREW_PREFIX=""
MIGRATION_FORMULAE=""
MIGRATION_REQUESTED_FORMULAE=""
MIGRATION_CASKS=""
MIGRATION_BACKUP_FILE=""

migration_log() {
  printf '%s\n' "$*"
}

migration_error() {
  printf 'error: %s\n' "$*" >&2
}

migration_die() {
  migration_error "$*"
  exit 1
}

migration_usage() {
  cat <<'EOF'
Usage: scripts/migrate-macos-brew-to-nix.sh [--yes] [--backup-dir DIR]

Save the installed Homebrew inventory, remove all installed Homebrew formulae
and casks, uninstall Homebrew with its official uninstaller, then run the
regular setup.sh flow to install/activate Nix and nix-darwin.

Options:
  --backup-dir DIR  Store the persistent Brewfile backup in DIR (default: $HOME)
  --yes             Skip the interactive prompt; explicitly authorize removal
  --help            Show this help

The generated Brewfile.backup-* file is never overwritten or deleted.
Homebrew is searched for in PATH and its standard macOS locations; set
MIGRATION_BREW_BIN to an executable path to use a custom installation.
If ~/nix-darwin-config/flake.nix exists, set NIX_DARWIN_CONFIG_DIR explicitly
to choose the configuration that the regular setup should activate.
EOF
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || migration_die "required command not found: $1"
}

resolve_brew_bin() {
  local candidate architecture
  local -a candidates=()

  if [[ -n "${MIGRATION_BREW_BIN:-}" ]]; then
    [[ -f "$MIGRATION_BREW_BIN" && -x "$MIGRATION_BREW_BIN" ]] \
      || migration_die "MIGRATION_BREW_BIN is not an executable file: $MIGRATION_BREW_BIN"
    BREW_BIN="$MIGRATION_BREW_BIN"
    return
  fi

  candidate="$(command -v brew 2>/dev/null || true)"
  [[ -n "$candidate" ]] && candidates+=("$candidate")

  architecture="$(uname -m)" || migration_die "could not determine macOS architecture"
  case "$architecture" in
    arm64|aarch64)
      candidates+=(/opt/homebrew/bin/brew /usr/local/bin/brew)
      ;;
    x86_64|amd64)
      candidates+=(/usr/local/bin/brew /opt/homebrew/bin/brew)
      ;;
    *)
      candidates+=(/opt/homebrew/bin/brew /usr/local/bin/brew)
      ;;
  esac

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" && -x "$candidate" ]]; then
      BREW_BIN="$candidate"
      return
    fi
  done

  migration_die "Homebrew executable not found in PATH or its standard macOS locations; set MIGRATION_BREW_BIN to its path"
}

check_nix_darwin_configuration() {
  local architecture configured_dir repository_dir

  repository_dir="$(cd "$MIGRATION_REPO_DIR/nix" && pwd -P)" \
    || migration_die "repository Nix flake directory is missing"
  configured_dir="${NIX_DARWIN_CONFIG_DIR:-$repository_dir}"

  [[ -d "$configured_dir" ]] \
    || migration_die "nix-darwin configuration directory not found: $configured_dir"
  configured_dir="$(cd "$configured_dir" && pwd -P)" \
    || migration_die "could not resolve nix-darwin configuration directory"
  [[ -f "$configured_dir/flake.nix" ]] \
    || migration_die "nix-darwin flake not found: $configured_dir/flake.nix"

  if [[ -z "${NIX_DARWIN_CONFIG_DIR:-}" && -f "$HOME/nix-darwin-config/flake.nix" ]]; then
    migration_die "existing flake found at $HOME/nix-darwin-config; set NIX_DARWIN_CONFIG_DIR explicitly before migrating"
  fi

  architecture="$(uname -m)" || migration_die "could not determine macOS architecture"
  case "$architecture" in
    arm64|aarch64)
      ;;
    x86_64|amd64)
      [[ "$configured_dir" != "$repository_dir" ]] \
        || migration_die "the repository flake supports aarch64-darwin only; select a compatible external NIX_DARWIN_CONFIG_DIR before migrating"
      ;;
    *)
      migration_die "unsupported macOS architecture: $architecture"
      ;;
  esac

  if [[ -n "${NIX_DARWIN_HOSTNAME:-}" ]]; then
    [[ "$NIX_DARWIN_HOSTNAME" =~ ^[A-Za-z0-9._-]+$ ]] \
      || migration_die "invalid NIX_DARWIN_HOSTNAME: $NIX_DARWIN_HOSTNAME"
  fi
}

preflight() {
  local operating_system

  [[ -n "${HOME:-}" ]] || migration_die "HOME is not set"
  require_command uname
  require_command curl
  require_command sudo
  require_command hostname
  require_command awk
  require_command date
  require_command mkdir
  [[ -x /bin/bash ]] || migration_die "required executable not found: /bin/bash"
  [[ -x "$MIGRATION_REPO_DIR/setup.sh" ]] || migration_die "setup.sh is missing or not executable"
  [[ -f "$MIGRATION_REPO_DIR/nix/flake.nix" && -f "$MIGRATION_REPO_DIR/nix/flake.lock" ]] \
    || migration_die "the repository's pinned Nix flake is incomplete"

  operating_system="$(uname -s)" || migration_die "could not determine operating system"
  [[ "$operating_system" == "Darwin" ]] || migration_die "this migration requires macOS"

  check_nix_darwin_configuration

  resolve_brew_bin
  CURL_BIN="$(command -v curl)"
  BREW_PREFIX="$("$BREW_BIN" --prefix)" \
    || migration_die "could not determine the Homebrew prefix"
  [[ -d "$BREW_PREFIX" ]] || migration_die "Homebrew prefix not found: $BREW_PREFIX"
  BREW_PREFIX="$(cd "$BREW_PREFIX" && pwd -P)" \
    || migration_die "could not resolve the Homebrew prefix"

  if ! "$MIGRATION_REPO_DIR/setup.sh" --list >/dev/null; then
    migration_die "the regular setup runner failed its preflight check"
  fi
}

confirm_migration() {
  local assume_yes="$1"
  local answer

  if [[ "$assume_yes" == 1 ]]; then
    migration_log "Proceeding with the explicit --yes confirmation."
    return
  fi

  [[ -t 0 ]] || migration_die "refusing to remove Homebrew non-interactively; rerun with --yes to explicitly authorize this migration"

  printf '%s\n' \
    "This will back up the installed Homebrew inventory, uninstall every installed formula and cask, uninstall Homebrew, and run the regular setup." \
    "The migration is destructive; package data and application settings are not backed up."
  printf 'Type REMOVE HOMEBREW to continue: '
  IFS= read -r answer || migration_die "no confirmation received; nothing was changed"
  [[ "$answer" == "REMOVE HOMEBREW" ]] \
    || migration_die "confirmation did not match; nothing was changed"
}

line_count() {
  local lines="$1"

  if [[ -z "$lines" ]]; then
    printf '0\n'
  else
    printf '%s\n' "$lines" | awk 'NF { count += 1 } END { print count + 0 }'
  fi
}

manifest_entry_count() {
  local directive="$1"
  local manifest="$2"

  awk -v directive="$directive" '$1 == directive { count += 1 } END { print count + 0 }' "$manifest"
}

manifest_missing_entries() {
  local directive="$1"
  local entries="$2"
  local entries_delimited="${entries//$'\n'/|}"
  local manifest="$3"

  awk -v directive="$directive" -v entries="$entries_delimited" '
    BEGIN {
      entry_count = split(entries, entry_names, /[|]/)
      for (i = 1; i <= entry_count; i += 1) {
        if (entry_names[i] != "") wanted[entry_names[i]] = 1
      }
    }
    $1 == directive {
      entry = $2
      sub(/^"/, "", entry)
      sub(/".*/, "", entry)
      found[entry] = 1
    }
    END {
      for (entry in wanted) {
        if (!(entry in found)) print entry
      }
    }
  ' "$manifest"
}

unique_backup_file() {
  local backup_dir="$1"
  local timestamp candidate suffix

  timestamp="$(date '+%Y%m%d-%H%M%S')" || migration_die "could not generate a backup timestamp"
  candidate="$backup_dir/Brewfile.backup-$timestamp"
  suffix=1
  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="$backup_dir/Brewfile.backup-$timestamp-$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

check_backup_location() {
  local backup_dir="$1"
  local resolved_backup_dir

  mkdir -p "$backup_dir" || migration_die "could not create backup directory: $backup_dir"
  resolved_backup_dir="$(cd "$backup_dir" && pwd -P)" \
    || migration_die "could not resolve backup directory: $backup_dir"
  case "$resolved_backup_dir/" in
    "$BREW_PREFIX/"*)
      migration_die "backup directory must be outside the Homebrew prefix ($BREW_PREFIX) so the uninstaller cannot remove it"
      ;;
  esac

  printf '%s\n' "$resolved_backup_dir"
}

capture_inventory() {
  MIGRATION_FORMULAE="$("$BREW_BIN" list --formula --full-name)" \
    || migration_die "could not list installed Homebrew formulae"
  MIGRATION_REQUESTED_FORMULAE="$("$BREW_BIN" list --formula --installed-on-request --full-name)" \
    || migration_die "could not list Homebrew formulae installed on request"
  MIGRATION_CASKS="$("$BREW_BIN" list --cask --full-name)" \
    || migration_die "could not list installed Homebrew casks"
}

create_backup() {
  local backup_dir="$1"
  local requested_formulae="$2"
  local installed_casks="$3"
  local requested_formula_count cask_count
  local manifest_formula_count manifest_cask_count missing_formulae missing_casks

  MIGRATION_BACKUP_FILE="$(unique_backup_file "$backup_dir")"
  migration_log "Writing installed Homebrew inventory to $MIGRATION_BACKUP_FILE..."
  if ! "$BREW_BIN" bundle dump --file "$MIGRATION_BACKUP_FILE"; then
    migration_die "Homebrew could not create the backup Brewfile"
  fi
  [[ -f "$MIGRATION_BACKUP_FILE" && ! -L "$MIGRATION_BACKUP_FILE" ]] \
    || migration_die "Homebrew did not create a regular backup file"

  manifest_formula_count="$(manifest_entry_count brew "$MIGRATION_BACKUP_FILE")"
  manifest_cask_count="$(manifest_entry_count cask "$MIGRATION_BACKUP_FILE")"
  missing_formulae="$(manifest_missing_entries brew "$requested_formulae" "$MIGRATION_BACKUP_FILE")"
  [[ -z "$missing_formulae" ]] \
    || migration_die "backup is missing installed-on-request formulae: ${missing_formulae//$'\n'/, }; no packages were removed"
  missing_casks="$(manifest_missing_entries cask "$installed_casks" "$MIGRATION_BACKUP_FILE")"
  [[ -z "$missing_casks" ]] \
    || migration_die "backup is missing installed casks: ${missing_casks//$'\n'/, }; no packages were removed"

  requested_formula_count="$(line_count "$requested_formulae")"
  cask_count="$(line_count "$installed_casks")"

  if [[ ! -s "$MIGRATION_BACKUP_FILE" ]]; then
    printf '%s\n' '# No installed Homebrew formulae or casks were present at migration time.' \
      >> "$MIGRATION_BACKUP_FILE"
  fi

  migration_log "Backup created and verified; it will be retained at $MIGRATION_BACKUP_FILE."
  migration_log "Backup contains $manifest_formula_count formula entries and $manifest_cask_count cask entries."
  migration_log "Verified all $requested_formula_count formulae installed on request and all $cask_count casks."
}

uninstall_formulae() {
  local formula

  if [[ -z "$MIGRATION_FORMULAE" ]]; then
    migration_log "No installed Homebrew formulae to remove."
    return
  fi

  while IFS= read -r formula; do
    [[ -n "$formula" ]] || continue
    migration_log "Uninstalling formula: $formula"
    "$BREW_BIN" uninstall --formula --force --ignore-dependencies "$formula"
  done <<< "$MIGRATION_FORMULAE"
}

uninstall_casks() {
  local cask

  if [[ -z "$MIGRATION_CASKS" ]]; then
    migration_log "No installed Homebrew casks to remove."
    return
  fi

  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    migration_log "Uninstalling cask: $cask"
    "$BREW_BIN" uninstall --cask --force "$cask"
  done <<< "$MIGRATION_CASKS"
}

uninstall_homebrew() {
  migration_log "Running Homebrew's official uninstaller..."
  "$CURL_BIN" --proto '=https' --tlsv1.2 -fsSL "$HOMEBREW_UNINSTALLER_URL" \
    | /bin/bash -s -- --force
  if [[ -e "$BREW_BIN" || -L "$BREW_BIN" ]] || command -v brew >/dev/null 2>&1; then
    migration_die "Homebrew's uninstaller returned, but its executable remains at $BREW_BIN or brew is still on PATH"
  fi
}

run_normal_setup() {
  migration_log "Running the regular setup flow to install/activate Nix and nix-darwin..."
  "$MIGRATION_REPO_DIR/setup.sh"
}

migration_report_failure() {
  local status="$1"

  if [[ "$status" -ne 0 && -n "$MIGRATION_BACKUP_FILE" && -f "$MIGRATION_BACKUP_FILE" ]]; then
    printf 'Migration stopped; the backup file was retained at: %s\n' \
      "$MIGRATION_BACKUP_FILE" >&2
    printf 'Check the failure above before continuing. The script does not roll back package removals.\n' >&2
  fi
}

main() {
  local assume_yes=0
  local backup_dir="${HOME:-}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        migration_usage
        return 0
        ;;
      --yes)
        assume_yes=1
        shift
        ;;
      --backup-dir)
        [[ $# -ge 2 ]] || migration_die "--backup-dir requires a directory"
        backup_dir="$2"
        shift 2
        ;;
      --backup-dir=*)
        backup_dir="${1#--backup-dir=}"
        shift
        ;;
      *)
        migration_die "unknown argument: $1"
        ;;
    esac
  done

  [[ -n "$backup_dir" ]] || migration_die "HOME is not set; specify --backup-dir"
  preflight
  confirm_migration "$assume_yes"

  umask 077
  backup_dir="$(check_backup_location "$backup_dir")"
  capture_inventory
  create_backup "$backup_dir" "$MIGRATION_REQUESTED_FORMULAE" "$MIGRATION_CASKS"

  uninstall_formulae
  uninstall_casks
  uninstall_homebrew
  run_normal_setup

  migration_log "Migration complete. Keep the backup Brewfile; it was not deleted: $MIGRATION_BACKUP_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'migration_report_failure "$?"' EXIT
  main "$@"
fi