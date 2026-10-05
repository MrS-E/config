#!/usr/bin/env bats

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os fedora
}

@test "Fedora package filter preserves descriptions for non-baseline packages" {
  local baseline="$BATS_TEST_TMPDIR/baseline"
  local manifest="$BATS_TEST_TMPDIR/manifest"
  local output="$BATS_TEST_TMPDIR/output"

  printf 'fedora-base\n' > "$baseline"
  printf '# Description: dependency\nfedora-base\n# Description: keep me\ncustom-package\n' > "$manifest"

  run "$REPO_DIR/scripts/filter-fedora-packages" filter "$baseline" "$manifest" "$output"

  assert_success
  run cat "$output"
  assert_output $'# Description: keep me\ncustom-package'
}

@test "Fedora package utility exposes description enrichment" {
  run "$REPO_DIR/scripts/filter-fedora-packages" --help

  assert_success
  assert_output_partial "--add-descriptions"
  assert_output_partial "capture [FILE]"
}

@test "Fedora package filter is not offered as zsh integration without Fedora tools" {
  run grep -F 'filter-fedora-packages' "$REPO_DIR/zshrc"
  assert_success
  run grep -F 'command -v rpm' "$REPO_DIR/zshrc"
  assert_success
  run grep -F 'command -v dnf' "$REPO_DIR/zshrc"
  assert_success
}