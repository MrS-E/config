#!/usr/bin/env bats
# Fedora-specific assertions. These assert ideal end state; for the current
# (pre-migration) scripts many will fail in containers (network installs,
# chsh, services) and are recorded as baseline limitations.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup_file() {
  # Run OS-specific Fedora steps before assertions (accept failures in containers).
  # Skip slow Flatpak app and external Nix installer steps.
  "$REPO_DIR/setup.sh" --exclude fedora/06-flatpak-apps.sh,fedora/16-nix.sh 2>/dev/null || true
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

@test "Nix step runs the official installer and configures flakes" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local nix_home="$BATS_TEST_TMPDIR/nix-home"
  mkdir -p "$mock_bin"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -e' \
    '[[ "${1:-}" == "--proto" ]]' \
    '[[ "${2:-}" == "=https" ]]' \
    '[[ "${3:-}" == "--tlsv1.2" ]]' \
    '[[ "${4:-}" == "-L" ]]' \
    '[[ "${5:-}" == "https://nixos.org/nix/install" ]]' \
    "printf '%s\\n' 'touch \"\$HOME/.nix-install-ran\"'" \
    > "$mock_bin/curl"
  chmod +x "$mock_bin/curl"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" \
    NIX_STEP="$REPO_DIR/setup/fedora/16-nix.sh" \
    bash -c '
      source "$NIX_STEP" help >/dev/null
      NIX_DEFAULT_PROFILE="$HOME/no-system-nix"
      NIX_USER_PROFILE="$HOME/no-user-nix"
      run
    '
  assert_success
  assert [ -f "$nix_home/.nix-install-ran" ]
  assert [ -f "$nix_home/.config/nix/nix.conf" ]
  run grep -Fxc -- "experimental-features = nix-command flakes" \
    "$nix_home/.config/nix/nix.conf"
  assert_success
  assert_output "1"
}
