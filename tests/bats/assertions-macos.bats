#!/usr/bin/env bats
# macOS-specific assertions (mocked environment). Validates OS detection,
# dispatch, and contract behavior — NOT real macOS or nix-darwin activation. See
# Containerfile.macos-mock.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os macos
}

create_nix_darwin_mocks() {
  local mock_bin="$1"
  mkdir -p "$mock_bin"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'if [[ "${1:-}" == "-m" ]]; then echo arm64; else echo Darwin; fi' \
    > "$mock_bin/uname"
  chmod +x "$mock_bin/uname"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'case "$*" in' \
    '  *"darwin-rebuild -- switch --flake "*"--no-write-lock-file")' \
    '    printf "%s\\n" switch >> "$HOME/nix-darwin-calls"' \
    '    ;;' \
    '  *) exit 2 ;;' \
    'esac' \
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
    '[[ "${1:-}" == /*/nix || "${1:-}" == nix ]]' \
    'nix_command="$1"' \
    'shift' \
    'exec "$nix_command" "$@"' \
    > "$mock_bin/sudo"
  chmod +x "$mock_bin/sudo"
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

@test "repository Nix package flake is present" {
  assert [ -f "$REPO_DIR/nix/flake.nix" ]
  assert [ -f "$REPO_DIR/nix/flake.lock" ]
  assert [ -f "$REPO_DIR/nix/home-manager/packages.nix" ]
}

@test "macOS mock does not provide Homebrew" {
  run command -v brew
  assert_failure
}

@test "zshrc has no Homebrew runtime setup" {
  run grep -Eiq 'brew|Homebrew|/opt/homebrew|HOMEBREW_PREFIX' "$REPO_DIR/zshrc"
  assert_failure
}

@test "zshrc prepends the Home Manager user profile on macOS" {
  run grep -F -- 'export PATH="$HOME/.nix-profile/bin:$PATH"' "$REPO_DIR/zshrc"
  assert_success
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

@test "nix-darwin step activates the repository flake on Apple Silicon" {
  local mock_bin="$BATS_TEST_TMPDIR/nix-darwin-mock-bin"
  local nix_home="$BATS_TEST_TMPDIR/nix-darwin-home"
  create_nix_darwin_mocks "$mock_bin"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    NIX_DARWIN_CONFIG_DIR="" NIX_DARWIN_HOSTNAME="" \
    NIX_DARWIN_ETC_DIR="$nix_home/mock-etc" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
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
  assert [ -f "$REPO_DIR/nix/flake.nix" ]
  run grep -Fxc -- "--extra-experimental-features nix-command flakes run path:$REPO_DIR/nix#darwin-rebuild -- switch --flake path:$REPO_DIR/nix#aarch64-darwin --no-write-lock-file" \
    "$nix_home/nix-darwin-nix-args"
  assert_success
  assert_output "2"
  run grep -Fxc -- switch "$nix_home/nix-darwin-calls"
  assert_success
  assert_output "2"
  assert [ -f "$nix_home/mock-etc/nix/nix.conf.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/bashrc.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/zshrc.before-nix-darwin" ]
  assert [ -f "$nix_home/mock-etc/resolver/ts.net" ]
  refute [ -e "$nix_home/mock-etc/resolver/ts.net.before-nix-darwin" ]
  refute [ -e "$nix_home/mock-etc/nix/nix.conf" ]
}

@test "nix-darwin external override selects its output without modifying the flake" {
  local mock_bin="$BATS_TEST_TMPDIR/nix-darwin-override-mock-bin"
  local nix_home="$BATS_TEST_TMPDIR/nix-darwin-override-home"
  local external_config="$nix_home/external-nix-darwin"
  create_nix_darwin_mocks "$mock_bin"
  mkdir -p "$external_config"
  printf '%s\n' 'external configuration must remain unchanged' > "$external_config/flake.nix"
  printf '%s\n' 'external lock must remain unchanged' > "$external_config/flake.lock"
  cp "$external_config/flake.nix" "$nix_home/flake.nix.expected"
  cp "$external_config/flake.lock" "$nix_home/flake.lock.expected"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    NIX_DARWIN_CONFIG_DIR="$external_config" NIX_DARWIN_HOSTNAME="test-mac" \
    NIX_DARWIN_ETC_DIR="$nix_home/mock-etc" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      presteps
      run
    '
  assert_success
  run cmp "$external_config/flake.nix" "$nix_home/flake.nix.expected"
  assert_success
  run cmp "$external_config/flake.lock" "$nix_home/flake.lock.expected"
  assert_success
  run grep -Fxc -- "--extra-experimental-features nix-command flakes run path:$REPO_DIR/nix#darwin-rebuild -- switch --flake path:$external_config#test-mac --no-write-lock-file" \
    "$nix_home/nix-darwin-nix-args"
  assert_success
  assert_output "1"
}

@test "nix-darwin step requires explicit selection when a legacy flake exists" {
  local nix_home="$BATS_TEST_TMPDIR/nix-darwin-legacy-home"
  mkdir -p "$nix_home/nix-darwin-config"
  printf '%s\n' 'preserve this existing configuration' \
    > "$nix_home/nix-darwin-config/flake.nix"
  cp "$nix_home/nix-darwin-config/flake.nix" "$nix_home/flake.nix.expected"

  run env HOME="$nix_home" NIX_DARWIN_CONFIG_DIR="" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      run
    '
  assert_failure
  assert_output_partial "existing nix-darwin flake found"
  run cmp "$nix_home/nix-darwin-config/flake.nix" "$nix_home/flake.nix.expected"
  assert_success
  refute [ -e "$nix_home/nix-darwin-calls" ]
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
  assert_output_partial "10-nix-darwin.sh"
  [[ "$output" != *"01-homebrew.sh"* ]]
  [[ "$output" != *"02-brew-bundle.sh"* ]]
}

@test "setup.sh creates the core dotfile symlinks under macos mock" {
  run_setup_allow_fail --only general/01-symlinks.sh
  assert_symlink_to "$HOME/.zshrc"     "$REPO_DIR/zshrc"
  assert_symlink_to "$HOME/.vimrc"     "$REPO_DIR/vimrc"
  assert_symlink_to "$HOME/.gitconfig" "$REPO_DIR/gitconfig"
  assert_symlink_to "$HOME/.config/nvim"   "$REPO_DIR/nvim"
  assert_symlink_to "$HOME/.config/lazygit" "$REPO_DIR/lazygit"
}
