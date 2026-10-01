#!/usr/bin/env bats
# Shell integration tests for executable scripts loaded by zshrc.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

@test "git-clone-remote is safe for zsh shell-integration discovery" {
  local fake_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fake_bin"

  cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env sh
case "$1" in
  fetch|branch|remote|push) exit 0 ;;
esac
exit 0
EOF
  chmod +x "$fake_bin/git"

  run env PATH="$fake_bin:$PATH" zsh -fc '
    eval "$($1 --shell-integration)"
  ' zsh "$REPO_DIR/scripts/git-clone-remote"

  assert_success
  assert_output ""
}

@test "zshrc initializes Starship after adding user-local bin to PATH" {
  local test_home="$BATS_TEST_TMPDIR/home"
  local fake_bin="$test_home/.local/bin"
  mkdir -p "$fake_bin"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'test "$1" = init && test "$2" = zsh || exit 2' \
    'printf "%s\\n" "STARSHIP_TEST_INITIALIZED=yes"' \
    > "$fake_bin/starship"
  chmod +x "$fake_bin/starship"

  run env HOME="$test_home" PATH="/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" zsh -f -c '
      source "$REPO_DIR/zshrc"
      [[ "${STARSHIP_TEST_INITIALIZED:-}" == yes ]]
    '

  assert_success
}