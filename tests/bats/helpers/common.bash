#!/usr/bin/env bash
# Shared bats helpers for the setup test harness.
# Sourced by bats files via: load "/workspace/tests/bats/helpers/common.bash"

REPO_DIR="${REPO_DIR:-/workspace}"
export HOME="${HOME:-/home/tester}"
export TEST_OS="${TEST_OS:-}"

# Run setup.sh capturing output; do NOT fail the test on non-zero exit.
# Use this for current scripts that are expected to fail partway in containers.
run_setup_allow_fail() {
  run "$REPO_DIR/setup.sh" "$@"
}

# Run setup.sh and require success.
run_setup() {
  run "$REPO_DIR/setup.sh" "$@"
  assert_success
}

# Resolve the OS step directory for the current TEST_OS.
os_step_dir() {
  case "${TEST_OS:-}" in
    macos|fedora|fedora-atomic|manjaro)
      printf '%s/setup/%s' "$REPO_DIR" "$TEST_OS" ;;
    *) printf '' ;;
  esac
}

# Count executable step scripts in the OS step directory.
count_os_steps() {
  local dir
  dir="$(os_step_dir)"
  [[ -d "$dir" ]] || { printf '0'; return 0; }
  find "$dir" -maxdepth 1 -name '*.sh' -perm -111 -type f 2>/dev/null | wc -l | tr -d ' '
}

# Skip the current test unless TEST_OS matches one of the given OS ids.
require_os() {
  local os
  for os in "$@"; do
    [[ "${TEST_OS:-}" == "$os" ]] && return 0
  done
  skip "TEST_OS=${TEST_OS:-<unset>} (requires: $*)"
}
