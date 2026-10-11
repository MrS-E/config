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

@test "Nix macOS package manifests exist" {
  assert [ -f "$REPO_DIR/nix/flake.nix" ]
  assert [ -f "$REPO_DIR/nix/packages/common.nix" ]
  assert [ -f "$REPO_DIR/nix/packages/darwin.nix" ]
  assert [ -f "$REPO_DIR/nix/packages/aarch64-darwin.nix" ]
  assert [ -f "$REPO_DIR/nix/home-manager/packages.nix" ]
}

@test "default macOS setup does not schedule Homebrew installation" {
  run "$REPO_DIR/setup.sh" --list
  assert_success
  [[ "$output" != *"01-homebrew.sh"* ]]
  [[ "$output" != *"02-brew-bundle.sh"* ]]
}

@test "Kitty permissions step opens both privacy panes" {
  run "$REPO_DIR/setup.sh" --only macos/08-kitty-permissions.sh
  assert_success
  assert_output_partial "Privacy_AllFiles"
  assert_output_partial "Privacy_LocalNetwork"
  assert_output_partial "In Full Disk Access, add /Applications/kitty.app"
}

@test "Kitty permissions step rejects non-macOS execution" {
  run env PATH="/usr/bin:/bin" "$REPO_DIR/setup/macos/08-kitty-permissions.sh" presteps
  assert_failure
  assert_output_partial "this step requires macOS"
}

@test "Kitty permissions step rejects an invalid command" {
  run "$REPO_DIR/setup/macos/08-kitty-permissions.sh"
  assert_failure
  assert_output_partial "usage:"
}

@test "Nix step runs the official installer and configures flakes" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local nix_home="$BATS_TEST_TMPDIR/nix-home"
  mkdir -p "$mock_bin" "$nix_home"
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
    NIX_STEP="$REPO_DIR/setup/macos/09-nix.sh" \
    bash -c '
      source "$NIX_STEP" help >/dev/null
      NIX_DEFAULT_PROFILE="$HOME/no-system-nix"
      NIX_USER_PROFILE="$HOME/no-user-nix"
      run
    '
  assert_success
  assert [ -f "$nix_home/.nix-install-ran" ]
  assert [ -d "$nix_home/.config/nix" ]
  assert [ -f "$nix_home/.config/nix/nix.conf" ]
  run grep -Fxc -- "experimental-features = nix-command flakes" \
    "$nix_home/.config/nix/nix.conf"
  assert_success
  assert_output "1"
}

@test "Nix step rejects non-macOS execution" {
  run env PATH="/usr/bin:/bin" "$REPO_DIR/setup/macos/09-nix.sh" presteps
  assert_failure
  assert_output_partial "this step requires macOS"
}

@test "nix-darwin step activates the repository flake without editing it" {
  local mock_bin="$BATS_TEST_TMPDIR/nix-darwin-mock-bin"
  local nix_home="$BATS_TEST_TMPDIR/nix-darwin-home"
  local flake_hash lock_hash
  mkdir -p "$mock_bin" "$nix_home"
  flake_hash="$(git -C "$REPO_DIR" hash-object nix/flake.nix)"
  lock_hash="$(git -C "$REPO_DIR" hash-object nix/flake.lock)"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'if [[ "${1:-}" == "-m" ]]; then echo arm64; else echo Darwin; fi' \
    > "$mock_bin/uname"
  chmod +x "$mock_bin/uname"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\\n" test-mac' \
    > "$mock_bin/hostname"
  chmod +x "$mock_bin/hostname"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    '[[ "${1:-}" == "--extra-experimental-features" ]]' \
    '[[ "${2:-}" == "nix-command flakes" ]]' \
    '[[ "${3:-}" == run ]]' \
    '[[ "${4:-}" == "git+file://$REPO_DIR?dir=nix#darwin-rebuild" ]]' \
    '[[ "${5:-}" == "--" ]]' \
    '[[ "${6:-}" == switch ]]' \
    '[[ "${7:-}" == "--flake" ]]' \
    '[[ "${8:-}" == "git+file://$REPO_DIR?dir=nix#aarch64-darwin" ]]' \
    '[[ "${9:-}" == "--no-write-lock-file" ]]' \
    'printf "%s\\n" "$*" >> "$HOME/nix-darwin-nix-args"' \
    > "$mock_bin/nix"
  chmod +x "$mock_bin/nix"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'if [[ "${1:-}" == mv ]]; then' \
    '  shift' \
    '  /bin/mv "$@"' \
    '  exit 0' \
    'fi' \
    'if [[ "${1:-}" == chown ]]; then exit 0; fi' \
    '[[ "${1:-}" == /*/nix || "${1:-}" == nix ]]' \
    'nix_command="$1"' \
    'shift' \
    'exec "$nix_command" "$@"' \
    > "$mock_bin/sudo"
  chmod +x "$mock_bin/sudo"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" NIX_DARWIN_CONFIG_DIR="" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      NIX_DARWIN_CONFIG_DIR="$REPO_DIR/nix"
      NIX_DARWIN_HOSTNAME="test-mac"
      NIX_DARWIN_ETC_DIR="$HOME/mock-etc"
      mkdir -p "$NIX_DARWIN_ETC_DIR/nix" "$NIX_DARWIN_ETC_DIR/resolver"
      printf "%s\n" "build-users-group = nixbld" > "$NIX_DARWIN_ETC_DIR/nix/nix.conf"
      printf "%s\n" "# System-wide zshrc" > "$NIX_DARWIN_ETC_DIR/zshrc"
      printf "%s\n" "# System-wide bashrc" > "$NIX_DARWIN_ETC_DIR/bashrc"
      printf "%s\n" "nameserver 100.100.100.100" > "$NIX_DARWIN_ETC_DIR/resolver/ts.net"
      presteps
      run
      run
    '
  assert_success
  [[ ! -e "$nix_home/nix-darwin-config/flake.nix" ]]
  [[ "$(git -C "$REPO_DIR" hash-object nix/flake.nix)" == "$flake_hash" ]]
  [[ "$(git -C "$REPO_DIR" hash-object nix/flake.lock)" == "$lock_hash" ]]
  run grep -Fc -- 'darwinConfigurations."aarch64-darwin"' "$REPO_DIR/nix/flake.nix"
  assert_success
  assert_output "1"
  run grep -Fxc -- "--extra-experimental-features nix-command flakes run git+file://$REPO_DIR?dir=nix#darwin-rebuild -- switch --flake git+file://$REPO_DIR?dir=nix#aarch64-darwin --no-write-lock-file" \
    "$nix_home/nix-darwin-nix-args"
  assert_success
  assert_output "2"
  assert [ -f "$nix_home/mock-etc/nix/nix.conf.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/bashrc.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/zshrc.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/resolver/ts.net" ]
  assert [ ! -e "$nix_home/mock-etc/resolver/ts.net.before-nix-darwin" ]
  assert [ ! -e "$nix_home/mock-etc/nix/nix.conf" ]
}

@test "nix-darwin step rejects non-macOS execution" {
  run env PATH="/usr/bin:/bin" "$REPO_DIR/setup/macos/10-nix-darwin.sh" presteps
  assert_failure
  assert_output_partial "this step requires macOS"
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
