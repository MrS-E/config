#!/usr/bin/env bats
# Idempotency tests: a second setup run must be a safe no-op.
# These run for every OS target. For the current (pre-migration) scripts,
# platform steps may fail in containers; these tests focus on the symlink
# layer, which is the part that is already idempotent.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

@test "repeated setup run does not create new symlink backups" {
  run_setup_allow_fail --only general/01-symlinks.sh
  local before
  before=$(find "$HOME" -maxdepth 3 -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' ')

  run_setup_allow_fail --only general/01-symlinks.sh
  local after
  after=$(find "$HOME" -maxdepth 3 -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' ')

  assert [ "$after" -eq "$before" ]
}

@test "repeated setup run leaves symlinks stable" {
  run_setup_allow_fail --only general/01-symlinks.sh
  local first
  first=$(readlink "$HOME/.zshrc" 2>/dev/null || true)

  run_setup_allow_fail --only general/01-symlinks.sh
  local second
  second=$(readlink "$HOME/.zshrc" 2>/dev/null || true)

  assert [ -n "$first" ]
  assert [ "$first" = "$second" ]
}
