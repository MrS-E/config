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

@test "SSH host config selects the YubiKey PKCS#11 provider" {
  run ssh -G -F "$REPO_DIR/ssh/config.d/homelab" tailscale-minix

  assert_success
  assert_output_partial "pkcs11provider /usr/lib64/libykcs11.so.2"
  assert_output_partial "identitiesonly yes"
}

@test "Fedora setup provides an Ed25519 PKCS#11-capable SSH client" {
  local step="$REPO_DIR/setup/fedora/16-openssh-ed25519-pkcs11.sh"

  run "$step" help

  assert_success
  assert_output_partial "OpenSSH 10.1p1"
  assert_output_partial "~/.local"
}

@test "Fedora setup installs SSH in the user-local bin directory" {
  local step="$REPO_DIR/setup/fedora/16-openssh-ed25519-pkcs11.sh"

  run grep -F 'OPENSSH_BIN="$OPENSSH_PREFIX/bin/ssh"' "$step"

  assert_success
  assert_output 'OPENSSH_BIN="$OPENSSH_PREFIX/bin/ssh"'
}

@test "Zsh resolves SSH from the user-local bin directory" {
  local home="$BATS_TEST_TMPDIR/home"

  mkdir -p "$home/.local/bin"
  touch "$home/.local/bin/ssh"
  chmod +x "$home/.local/bin/ssh"

  run env HOME="$home" PATH="/usr/bin:/bin" zsh -df -c \
    'source "$1" >/dev/null 2>&1 && command -v ssh' _ "$REPO_DIR/zshrc"

  assert_success
  assert_output "$home/.local/bin/ssh"
}

@test "Fedora setup installs only OpenSSH client tools" {
  local step="$REPO_DIR/setup/fedora/16-openssh-ed25519-pkcs11.sh"

  run sed -n '/^[[:space:]]*make install$/p' "$step"

  assert_success
  assert_output ""
}

@test "Fedora setup isolates the OpenSSH client configuration" {
  local step="$REPO_DIR/setup/fedora/16-openssh-ed25519-pkcs11.sh"

  run sed -n '/--sysconfdir=\/etc\/ssh/p' "$step"

  assert_success
  assert_output ""
}

@test "Fedora setup reads the PIV slot 9d public key through ssh-keygen" {
  local step="$REPO_DIR/setup/fedora/16-openssh-ed25519-pkcs11.sh"

  run grep -F '"$SSH_KEYGEN_BIN" -D "$YUBIKEY_PROVIDER"' "$step"

  assert_success
  assert_output_partial '"$SSH_KEYGEN_BIN" -D "$YUBIKEY_PROVIDER"'
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