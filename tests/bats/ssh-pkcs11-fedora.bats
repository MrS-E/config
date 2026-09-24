#!/usr/bin/env bats
# Fedora-specific SSH PKCS#11 provider checks.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os fedora
}

@test "Fedora PKCS#11 provider filter resolves the YubiKey library" {
  run "$REPO_DIR/ssh/pkcs11-filter.sh" smudge < "$REPO_DIR/ssh/config.d/private"
  assert_success
  assert_output_partial "PKCS11Provider /usr/lib64/libykcs11.so.2"
  [[ "$output" != *TODO_VERIFY* ]]
  assert [ -r /usr/lib64/libykcs11.so.2 ]
}

@test "Fedora PKCS#11 provider filter resolves the OpenSC library" {
  run "$REPO_DIR/ssh/pkcs11-filter.sh" smudge < "$REPO_DIR/ssh/config.d/infra"
  assert_success
  assert_output_partial "PKCS11Provider /usr/lib64/pkcs11/opensc-pkcs11.so"
  assert [ -r /usr/lib64/pkcs11/opensc-pkcs11.so ]
}

@test "Fedora SSH host config accepts resolved PKCS#11 providers" {
  local config
  config="$(mktemp)"
  "$REPO_DIR/ssh/pkcs11-filter.sh" smudge < "$REPO_DIR/ssh/config.d/private" > "$config"
  run ssh -G -F "$config" github.com
  rm -f "$config"
  assert_success
  assert_output_partial "pkcs11provider /usr/lib64/libykcs11.so.2"
}

@test "git filter refreshes existing Fedora SSH configs" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo/setup/general" "$repo/ssh/config.d"
  cp -a "$REPO_DIR/.git" "$repo/"
  cp "$REPO_DIR/.gitattributes" "$REPO_DIR/setup.sh" "$repo/"
  cp "$REPO_DIR/setup/general/common.bash" "$REPO_DIR/setup/general/02-git-filters.sh" "$repo/setup/general/"
  cp "$REPO_DIR/ssh/pkcs11-filter.sh" "$REPO_DIR/ssh/providers.fedora" "$repo/ssh/"
  cp "$REPO_DIR/ssh/config.d/"* "$repo/ssh/config.d/"
  "$REPO_DIR/ssh/pkcs11-filter.sh" clean < "$REPO_DIR/ssh/config.d/private" > "$repo/ssh/config.d/private"
  run bash -c 'cd "$1" && "$1/setup.sh" --only general/02-git-filters.sh' _ "$repo"
  assert_success
  run grep -F "PKCS11Provider /usr/lib64/libykcs11.so.2" "$repo/ssh/config.d/private"
  assert_success
}