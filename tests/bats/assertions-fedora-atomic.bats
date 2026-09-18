#!/usr/bin/env bats
# Fedora Atomic-specific assertions. rpm-ostree/toolbox are mocked in the
# container (see Containerfile.fedora-atomic); Flatpak remains real where
# feasible. Many assertions will fail in the baseline and are recorded.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup_file() {
  # Run OS-specific Fedora Atomic steps before assertions (accept failures).
  # Skip slow Flatpak app installs.
  "$REPO_DIR/setup.sh" --exclude fedora-atomic/07-flatpak-apps.sh 2>/dev/null || true
}

setup() {
  require_os fedora-atomic
}

@test "fedora-release marker is present" {
  assert [ -f /etc/fedora-release ]
}

@test "rpm-ostree is available (mocked)" {
  run command -v rpm-ostree
  assert_success
}

@test "fedora-atomic package manifests exist" {
  assert [ -f "$REPO_DIR/setup/fedora-atomic/rpm-ostree.txt" ]
  assert [ -f "$REPO_DIR/setup/fedora-atomic/flatpak.txt" ]
  assert [ -f "$REPO_DIR/setup/fedora-atomic/toolboxes.txt" ]
  assert [ -d "$REPO_DIR/setup/fedora-atomic/toolboxes" ]
}

@test "toolbox manifest files exist" {
  while IFS= read -r tb; do
    [[ -z "$tb" || "$tb" =~ ^[[:space:]]*# ]] && continue
    assert [ -f "$REPO_DIR/setup/fedora-atomic/toolboxes/$tb.txt" ]
  done < "$REPO_DIR/setup/fedora-atomic/toolboxes.txt"
}

@test "flatpak remote flathub exists" {
  assert_flatpak_remote flathub
}

@test "flatpak apps from manifest are installed" {
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
    assert_flatpak_installed "$app"
  done < "$REPO_DIR/setup/fedora-atomic/flatpak.txt"
}

@test "zsh plugin directories exist" {
  assert_dir_exists "$HOME/.zsh/zsh-autosuggestions"
  assert_dir_exists "$HOME/.zsh/zsh-syntax-highlighting"
  assert_dir_exists "$HOME/.zsh/zsh-autocomplete"
}
