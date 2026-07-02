#!/usr/bin/env bats
# macOS-specific assertions (mocked environment). Validates OS detection,
# dispatch, and contract behavior — NOT real Homebrew. See
# Containerfile.macos-mock.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os macos
}

@test "uname -s reports Darwin (mocked)" {
  run uname -s
  assert_success
  assert_output "Darwin"
}

@test "macOS step directory exists with executable step scripts" {
  local dir="$REPO_DIR/setup/macos"
  assert [ -d "$dir" ]
  local count
  count=$(find "$dir" -maxdepth 1 -name '*.sh' -perm -111 -type f 2>/dev/null | wc -l | tr -d ' ')
  assert [ "$count" -gt 0 ]
}

@test "Brewfile manifest exists" {
  assert [ -f "$REPO_DIR/setup/macos/Brewfile" ]
}

@test "mock brew is on PATH" {
  run command -v brew
  assert_success
}

@test "setup.sh detects macos and discovers macos steps" {
  run "$REPO_DIR/setup.sh" --list
  assert_success
  assert_output_partial "Detected OS: macos"
  assert_output_partial "macos/"
}

@test "setup.sh creates the core dotfile symlinks under macos mock" {
  run_setup_allow_fail --only general/01-symlinks.sh
  assert_symlink_to "$HOME/.zshrc"     "$REPO_DIR/zshrc"
  assert_symlink_to "$HOME/.vimrc"     "$REPO_DIR/vimrc"
  assert_symlink_to "$HOME/.gitconfig" "$REPO_DIR/gitconfig"
  assert_symlink_to "$HOME/.config/nvim"   "$REPO_DIR/nvim"
  assert_symlink_to "$HOME/.config/lazygit" "$REPO_DIR/lazygit"
}
