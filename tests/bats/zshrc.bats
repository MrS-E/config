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