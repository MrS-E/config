#!/usr/bin/env bash
# Custom assertion helpers for the setup test harness.
# bats-core only — does NOT depend on bats-assert/bats-support, which are not
# packaged in the base bats RPMs used by the test containers.

# Print a diagnostic line on bats' output channel (fd 3) and fail the test.
_fail() {
  echo "# $*" >&3
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    _fail "expected success, got status $status"
    _fail "output: $output"
    return 1
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    _fail "expected failure, got status 0"
    _fail "output: $output"
    return 1
  fi
}

assert_output_partial() {
  local needle="$1"
  if [[ "$output" != *"$needle"* ]]; then
    _fail "expected output to contain: $needle"
    _fail "output: $output"
    return 1
  fi
}

# bats-assert-compatible `assert` wrapper: run the given command and fail on
# non-zero. Allows `assert [ -x "$f" ]` style usage without bats-assert.
assert() {
  "$@"
}

# bats-assert-compatible `assert_output`: exact match, or `--partial` substring.
assert_output() {
  if [[ "${1:-}" == "--partial" ]]; then
    shift
    assert_output_partial "$1"
  else
    if [[ "$output" != "$1" ]]; then
      _fail "expected output: $1"
      _fail "actual:   $output"
      return 1
    fi
  fi
}

# Assert that $1 is a symlink pointing exactly at $2.
assert_symlink_to() {
  local link="$1"
  local target="$2"
  [ -L "$link" ] || { _fail "not a symlink: $link"; return 1; }
  [ "$(readlink "$link")" = "$target" ] || {
    _fail "symlink $link -> $(readlink "$link") (expected $target)"
    return 1
  }
}

# Assert that $1 is a symlink (target not checked).
assert_symlink_exists() {
  [ -L "$1" ] || { _fail "not a symlink: $1"; return 1; }
}

# Assert that $1 is a directory.
assert_dir_exists() {
  [ -d "$1" ] || { _fail "not a directory: $1"; return 1; }
}

# Assert that every non-comment, non-empty package listed in manifest $1 is
# installed via `rpm -q`.
assert_manifest_packages_installed_rpm() {
  local file="$1"
  local missing=0
  [ -f "$file" ] || { _fail "manifest not found: $file"; return 1; }
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    if ! rpm -q "$pkg" >/dev/null 2>&1; then
      _fail "missing rpm package: $pkg"
      missing=1
    fi
  done < "$file"
  [ "$missing" -eq 0 ]
}

# Assert that every non-comment, non-empty package listed in manifest $1 is
# installed via `pacman -Q`.
assert_manifest_packages_installed_pacman() {
  local file="$1"
  local missing=0
  [ -f "$file" ] || { _fail "manifest not found: $file"; return 1; }
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      _fail "missing pacman package: $pkg"
      missing=1
    fi
  done < "$file"
  [ "$missing" -eq 0 ]
}

# Assert that a flatpak remote named $1 exists.
assert_flatpak_remote() {
  run flatpak remotes 2>/dev/null
  assert_success || return 1
  assert_output_partial "$1"
}

# Assert that flatpak app $1 is installed.
assert_flatpak_installed() {
  run flatpak list 2>/dev/null
  assert_success || return 1
  assert_output_partial "$1"
}
