#!/usr/bin/env bats

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os fedora
}

@test "Fedora package filter preserves descriptions for non-baseline packages" {
  local baseline="$BATS_TEST_TMPDIR/baseline"
  local manifest="$BATS_TEST_TMPDIR/manifest"

  printf 'fedora-base\n' > "$baseline"
  printf '# Description: dependency\nfedora-base\n# Description: keep me\ncustom-package\n' > "$manifest"

  run "$REPO_DIR/scripts/filter-fedora-packages" filter "$baseline" "$manifest" "$BATS_TEST_TMPDIR/filtered-manifest"

  assert_success
  run cat "$BATS_TEST_TMPDIR/filtered-manifest"
  assert_output $'# Description: keep me\ncustom-package'
}

@test "Fedora package utility exposes description enrichment" {
  run "$REPO_DIR/scripts/filter-fedora-packages" --help

  assert_success
  assert_output_partial "--add-descriptions"
  assert_output_partial "capture [FILE]"
}

@test "Fedora package utility shell integration exits cleanly without Fedora tools" {
  local tools="$BATS_TEST_TMPDIR/no-fedora-tools"
  mkdir -p "$tools"
  ln -s "$(command -v dirname)" "$tools/dirname"

  run env PATH="$tools" /usr/bin/bash "$REPO_DIR/scripts/filter-fedora-packages" --shell-integration

  assert_success
  assert_output ""
}