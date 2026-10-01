#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
load "$REPO_DIR/tests/bats/helpers/common.bash"
load "$REPO_DIR/tests/bats/helpers/assertions.bash"

# shellcheck source=scripts/migrate-macos-brew-to-nix.sh
source "$REPO_DIR/scripts/migrate-macos-brew-to-nix.sh"

setup() {
  require_os macos
}

create_migration_mocks() {
  local mock_bin="$1"

  mkdir -p "$mock_bin"
  mkdir -p "$MIGRATION_MOCK_BREW_PREFIX"
  export MIGRATION_UNINSTALLER_SCRIPT='printf "official-uninstaller %s\n" "$*" >> "$MIGRATION_TEST_LOG"; rm -f "$MIGRATION_MOCK_BREW"'

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case "${1:-}" in' \
    '  -s) printf "%s\n" Darwin ;;' \
    '  -m) printf "%s\n" arm64 ;;' \
    '  *) exec /usr/bin/uname "$@" ;;' \
    'esac' \
    > "$mock_bin/uname"
  chmod +x "$mock_bin/uname"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "brew %s\n" "$*" >> "$MIGRATION_TEST_LOG"' \
    'case "$*" in' \
    '  --prefix) printf "%s\n" "$MIGRATION_MOCK_BREW_PREFIX" ;;' \
    '  "list --formula --full-name") printf "%s\n" formula-one formula-two ;;' \
    '  "list --cask --full-name") printf "%s\n" cask-one ;;' \
    '  "bundle dump --file "*)' \
    '    if [[ "${MIGRATION_MOCK_BACKUP_MISSING:-0}" == 1 ]]; then' \
    '      printf "%s\n" "tap \"homebrew/core\"" "brew \"formula-one\"" "cask \"cask-one\"" > "$4"' \
    '    else' \
    '      printf "%s\n" "tap \"homebrew/core\"" "brew \"formula-one\"" "brew \"formula-two\"" "cask \"cask-one\"" > "$4"' \
    '    fi' \
    '    ;;' \
    '  "uninstall --formula --force --ignore-dependencies formula-one"|"uninstall --formula --force --ignore-dependencies formula-two"|"uninstall --cask --force cask-one") ;;' \
    '  *) printf "unexpected brew invocation: %s\n" "$*" >&2; exit 2 ;;' \
    'esac' \
    > "$mock_bin/brew"
  chmod +x "$mock_bin/brew"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "curl %s\n" "$*" >> "$MIGRATION_TEST_LOG"' \
    'printf "%s\n" "$MIGRATION_UNINSTALLER_SCRIPT"' \
    > "$mock_bin/curl"
  chmod +x "$mock_bin/curl"
}

@test "migration utility is not discovered as a normal setup step" {
  run "$REPO_DIR/setup.sh" --list
  assert_success
  [[ "$output" != *"migrate-macos-brew-to-nix"* ]]
}

@test "migration saves a verified Brewfile and only then removes Homebrew and runs setup" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local backup_dir="$BATS_TEST_TMPDIR/brew-backups"
  local log_file="$BATS_TEST_TMPDIR/migration.log"
  local log_contents before_uninstaller after_uninstaller backup_file

  export MIGRATION_TEST_LOG="$log_file"
  export MIGRATION_MOCK_BREW_PREFIX="$BATS_TEST_TMPDIR/homebrew-prefix"
  export MIGRATION_MOCK_BREW="$mock_bin/brew"
  export NIX_DARWIN_CONFIG_DIR="$REPO_DIR/nix"
  export NIX_DARWIN_HOSTNAME=""
  create_migration_mocks "$mock_bin"
  export PATH="$mock_bin:/usr/bin:/bin:/usr/sbin:/sbin"

  run_normal_setup() {
    printf '%s\n' 'normal setup' >> "$MIGRATION_TEST_LOG"
  }

  main --yes --backup-dir "$backup_dir"

  backup_file="$MIGRATION_BACKUP_FILE"
  assert [ -f "$backup_file" ]
  assert [ ! -e "$MIGRATION_MOCK_BREW" ]
  assert [ "$(awk '$1 == "brew" { count += 1 } END { print count + 0 }' "$backup_file")" -eq 2 ]
  assert [ "$(awk '$1 == "cask" { count += 1 } END { print count + 0 }' "$backup_file")" -eq 1 ]

  log_contents="$(<"$log_file")"
  [[ "$log_contents" == *"brew uninstall --formula --force --ignore-dependencies formula-one"* ]]
  [[ "$log_contents" == *"brew uninstall --cask --force cask-one"* ]]
  before_uninstaller="${log_contents%%official-uninstaller --force*}"
  after_uninstaller="${log_contents#*official-uninstaller --force}"
  [[ "$before_uninstaller" == *"brew uninstall --cask --force cask-one"* ]]
  [[ "$after_uninstaller" == *"normal setup"* ]]
}

@test "migration refuses non-interactive removal without explicit confirmation" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local backup_dir="$BATS_TEST_TMPDIR/brew-backups"
  local log_file="$BATS_TEST_TMPDIR/migration.log"

  export MIGRATION_TEST_LOG="$log_file"
  export MIGRATION_MOCK_BREW_PREFIX="$BATS_TEST_TMPDIR/homebrew-prefix"
  export MIGRATION_MOCK_BREW="$mock_bin/brew"
  export NIX_DARWIN_CONFIG_DIR="$REPO_DIR/nix"
  export NIX_DARWIN_HOSTNAME=""
  create_migration_mocks "$mock_bin"

  run env PATH="$mock_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    MIGRATION_TEST_LOG="$log_file" \
    MIGRATION_MOCK_BREW_PREFIX="$MIGRATION_MOCK_BREW_PREFIX" \
    MIGRATION_MOCK_BREW="$MIGRATION_MOCK_BREW" \
    NIX_DARWIN_CONFIG_DIR="$NIX_DARWIN_CONFIG_DIR" \
    NIX_DARWIN_HOSTNAME="" \
    "$REPO_DIR/scripts/migrate-macos-brew-to-nix.sh" --backup-dir "$backup_dir"

  assert_failure
  assert_output --partial "rerun with --yes"
  assert [ ! -e "$backup_dir" ]
  [[ "$(<"$log_file")" == *"brew --prefix"* ]]
  [[ "$(<"$log_file")" != *"brew list --formula"* ]]
}

@test "migration rejects a backup destination that the Homebrew uninstaller would remove" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local log_file="$BATS_TEST_TMPDIR/migration.log"

  export MIGRATION_TEST_LOG="$log_file"
  export MIGRATION_MOCK_BREW_PREFIX="$BATS_TEST_TMPDIR/homebrew-prefix"
  export MIGRATION_MOCK_BREW="$mock_bin/brew"
  export NIX_DARWIN_CONFIG_DIR="$REPO_DIR/nix"
  export NIX_DARWIN_HOSTNAME=""
  create_migration_mocks "$mock_bin"

  run env PATH="$mock_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    MIGRATION_TEST_LOG="$log_file" \
    MIGRATION_MOCK_BREW_PREFIX="$MIGRATION_MOCK_BREW_PREFIX" \
    MIGRATION_MOCK_BREW="$MIGRATION_MOCK_BREW" \
    NIX_DARWIN_CONFIG_DIR="$NIX_DARWIN_CONFIG_DIR" \
    NIX_DARWIN_HOSTNAME="" \
    "$REPO_DIR/scripts/migrate-macos-brew-to-nix.sh" --yes \
    --backup-dir "$MIGRATION_MOCK_BREW_PREFIX"

  assert_failure
  assert_output --partial "backup directory must be outside the Homebrew prefix"
  [[ "$(<"$log_file")" != *"brew uninstall"* ]]
  [[ "$(<"$log_file")" != *"brew bundle dump"* ]]
}

@test "migration stops if the backup does not contain every installed package" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local backup_dir="$BATS_TEST_TMPDIR/brew-backups"
  local log_file="$BATS_TEST_TMPDIR/migration.log"
  local backup_file

  export MIGRATION_TEST_LOG="$log_file"
  export MIGRATION_MOCK_BREW_PREFIX="$BATS_TEST_TMPDIR/homebrew-prefix"
  export MIGRATION_MOCK_BREW="$mock_bin/brew"
  export NIX_DARWIN_CONFIG_DIR="$REPO_DIR/nix"
  export NIX_DARWIN_HOSTNAME=""
  create_migration_mocks "$mock_bin"

  run env PATH="$mock_bin:/usr/bin:/bin:/usr/sbin:/sbin" \
    MIGRATION_TEST_LOG="$log_file" \
    MIGRATION_MOCK_BREW_PREFIX="$MIGRATION_MOCK_BREW_PREFIX" \
    MIGRATION_MOCK_BREW="$MIGRATION_MOCK_BREW" \
    MIGRATION_MOCK_BACKUP_MISSING=1 \
    NIX_DARWIN_CONFIG_DIR="$NIX_DARWIN_CONFIG_DIR" \
    NIX_DARWIN_HOSTNAME="" \
    "$REPO_DIR/scripts/migrate-macos-brew-to-nix.sh" --yes --backup-dir "$backup_dir"

  assert_failure
  assert_output --partial "backup contains 1 formula entries"
  backup_file="$(find "$backup_dir" -maxdepth 1 -type f -name 'Brewfile.backup-*' -print -quit)"
  assert [ -f "$backup_file" ]
  [[ "$(<"$log_file")" != *"brew uninstall"* ]]
  [[ "$(<"$log_file")" != *"curl "* ]]
}