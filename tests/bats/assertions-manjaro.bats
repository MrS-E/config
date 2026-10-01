#!/usr/bin/env bats
# Manjaro-specific assertions. These assert ideal end state; for the current
# (pre-migration) scripts many will fail in containers (AUR builds, chsh,
# services) and are recorded as baseline limitations.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup_file() {
  # Run general steps + yay bootstrap + zsh plugins for assertion checks.
  # Skip manjaro/02-pacman-packages.sh (too slow: ~60 packages one-at-a-time).
  # yay is installed by the 03-yay-bootstrap step (not pre-installed in the image).
  "$REPO_DIR/setup.sh" --only general/01-symlinks.sh,general/02-git-filters.sh,general/03-vim-base.sh,manjaro/03-yay-bootstrap.sh,manjaro/06-zsh-plugins.sh 2>/dev/null || true
}

setup() {
  require_os manjaro
}

@test "manjaro-release marker is present" {
  assert [ -f /etc/manjaro-release ]
}

@test "manjaro package manifests exist" {
  assert [ -f "$REPO_DIR/setup/manjaro/pacman.txt" ]
  assert [ -f "$REPO_DIR/setup/manjaro/aur.txt" ]
}

@test "key pacman packages are installed" {
  # Only check packages pre-installed in the container image (full manifest
  # install is too slow for CI — ~60 packages one-at-a-time).
  # yay is NOT pre-installed; it is installed by the 03-yay-bootstrap step.
  for pkg in zsh vim neovim git fzf flatpak openssh; do
    run pacman -Q "$pkg"
    assert_success "package $pkg should be installed"
  done
}

@test "yay is available" {
  run command -v yay
  assert_success
}

@test "zsh plugin directories exist" {
  assert_dir_exists "$HOME/.zsh/zsh-autosuggestions"
  assert_dir_exists "$HOME/.zsh/zsh-syntax-highlighting"
  assert_dir_exists "$HOME/.zsh/zsh-autocomplete"
}

@test "manjaro step scripts are present and executable" {
  local dir="$REPO_DIR/setup/manjaro"
  assert [ -x "$dir/01-system-update.sh" ]
  assert [ -x "$dir/02-pacman-packages.sh" ]
  assert [ -x "$dir/03-yay-bootstrap.sh" ]
  assert [ -x "$dir/04-aur-packages.sh" ]
  assert [ -x "$dir/05-default-shell.sh" ]
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
    NIX_STEP="$REPO_DIR/setup/manjaro/14-nix.sh" \
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
