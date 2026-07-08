#!/usr/bin/env bats
# Smoke tests: setup.sh runs and produces the expected dotfile symlinks.
# These run for every OS target.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

@test "setup.sh exists and is executable" {
  assert [ -x "$REPO_DIR/setup.sh" ]
}

@test "OS step directory exists with executable step scripts" {
  local dir
  dir="$(os_step_dir)"
  [[ -n "$dir" ]] || skip "no TEST_OS set"
  assert [ -d "$dir" ]
  local count
  count="$(count_os_steps)"
  echo "# found $count step scripts in $dir" >&3
  assert [ "$count" -gt 0 ]
}

@test "setup.sh creates the core dotfile symlinks" {
  # Run only general steps to create symlinks quickly (skip slow OS-specific
  # package installs like Flatpak).
  run_setup_allow_fail --only general/01-symlinks.sh,general/02-git-filters.sh,general/03-vim-base.sh
  assert_symlink_to "$HOME/.zshrc"     "$REPO_DIR/zshrc"
  assert_symlink_to "$HOME/.vimrc"     "$REPO_DIR/vimrc"
  assert_symlink_to "$HOME/.gitconfig" "$REPO_DIR/gitconfig"
  assert_symlink_to "$HOME/.config/nvim"   "$REPO_DIR/nvim"
  assert_symlink_to "$HOME/.config/lazygit" "$REPO_DIR/lazygit"
  assert_symlink_to "$HOME/.junie"     "$REPO_DIR/junie"
}

@test "setup.sh links ghostty config when present" {
  assert [ -d "$REPO_DIR/ghostty" ]
  run_setup_allow_fail --only general/01-symlinks.sh
  assert_symlink_to "$HOME/.config/ghostty" "$REPO_DIR/ghostty"
}

@test "setup.sh links ssh config" {
  assert [ -f "$REPO_DIR/ssh/config" ]
  run_setup_allow_fail --only general/01-symlinks.sh
  assert_symlink_exists "$HOME/.ssh/config"
}
