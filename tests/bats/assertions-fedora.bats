#!/usr/bin/env bats
# Fedora-specific assertions. These assert ideal end state; for the current
# (pre-migration) scripts many will fail in containers (network installs,
# chsh, services) and are recorded as baseline limitations.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup_file() {
  # Run OS-specific Fedora steps before assertions (accept failures in containers).
  # Skip slow Flatpak app installs; remote-only step is fast enough.
  "$REPO_DIR/setup.sh" --exclude fedora/06-flatpak-apps.sh 2>/dev/null || true
}

setup() {
  require_os fedora
}

@test "fedora-release marker is present" {
  assert [ -f /etc/fedora-release ]
}

@test "classic fedora target has no rpm-ostree" {
  run command -v rpm-ostree
  assert_failure
}

@test "fedora package manifests exist" {
  assert [ -f "$REPO_DIR/setup/fedora/dnf.txt" ]
  assert [ -f "$REPO_DIR/setup/fedora/flatpak.txt" ]
  assert [ -f "$REPO_DIR/setup/fedora/copr.txt" ]
}

@test "dnf packages from manifest are installed" {
  assert_manifest_packages_installed_rpm "$REPO_DIR/setup/fedora/dnf.txt"
}

@test "flatpak remote flathub exists" {
  assert_flatpak_remote flathub
}

@test "flatpak apps from manifest are installed" {
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
    assert_flatpak_installed "$app"
  done < "$REPO_DIR/setup/fedora/flatpak.txt"
}

@test "zsh plugin directories exist" {
  assert_dir_exists "$HOME/.zsh/zsh-autosuggestions"
  assert_dir_exists "$HOME/.zsh/zsh-syntax-highlighting"
  assert_dir_exists "$HOME/.zsh/zsh-autocomplete"
}
