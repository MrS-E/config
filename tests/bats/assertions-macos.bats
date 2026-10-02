#!/usr/bin/env bats
# macOS-specific assertions (mocked environment). Validates OS detection,
# dispatch, and contract behavior — NOT real Homebrew. See
# Containerfile.macos-mock.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

setup() {
  require_os macos
  unset HOMEBREW_TEST_LOG HOMEBREW_TEST_INSTALLER HOMEBREW_TEST_BREW_PATH
}

create_homebrew_curl_mock() {
  local mock_bin="$1"

  mkdir -p "$mock_bin"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "curl %s\n" "$*" >> "$HOMEBREW_TEST_LOG"' \
    '[[ "${1:-}" == "-fsSL" ]]' \
    '[[ "${2:-}" == "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" ]]' \
    'printf "%s\n" "$HOMEBREW_TEST_INSTALLER"' \
    > "$mock_bin/curl"
  chmod +x "$mock_bin/curl"
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

@test "macOS setup does not require a checked-in Brewfile" {
  assert [ ! -e "$REPO_DIR/setup/macos/Brewfile" ]
}

@test "default macOS setup uses nix-darwin instead of standalone brew bundle steps" {
  run "$REPO_DIR/setup.sh" --list
  assert_success
  assert_output_partial "macos/10-nix-darwin.sh"
  [[ "$output" != *"01-homebrew.sh"* ]]
  [[ "$output" != *"02-brew-bundle.sh"* ]]
}

@test "nix-darwin step skips Homebrew bootstrap when brew is already installed" {
  local mock_bin="$BATS_TEST_TMPDIR/homebrew-existing-bin"
  local nix_home="$BATS_TEST_TMPDIR/homebrew-existing-home"
  mkdir -p "$mock_bin" "$nix_home"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'exit 0' \
    > "$mock_bin/brew"
  chmod +x "$mock_bin/brew"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\n" called > "$HOME/homebrew-installer-called"' \
    'exit 99' \
    > "$mock_bin/curl"
  chmod +x "$mock_bin/curl"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/bin:/bin" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      ensure_homebrew
    '
  assert_success
  assert_output_partial "Homebrew already installed; skipping bootstrap."
  assert [ ! -e "$nix_home/homebrew-installer-called" ]
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
  local bootstrap_log="$nix_home/homebrew-bootstrap.log"
  local installer_script curl_line installer_line activation_line
  printf -v installer_script '%s\n' \
    '[[ "${NONINTERACTIVE:-}" == 1 ]] || exit 44' \
    'printf "%s\n" "installer NONINTERACTIVE=$NONINTERACTIVE" >> "$HOMEBREW_TEST_LOG"' \
    'printf "%s\n" "#!/usr/bin/env bash" "exit 0" > "$HOMEBREW_TEST_BREW_PATH"' \
    'chmod +x "$HOMEBREW_TEST_BREW_PATH"'
  create_homebrew_curl_mock "$mock_bin"
  flake_hash="$(cksum "$REPO_DIR/nix/flake.nix")"
  lock_hash="$(cksum "$REPO_DIR/nix/flake.lock")"

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
    'printf "%s\n" "nix activation" >> "$HOMEBREW_TEST_LOG"' \
    '[[ "${1:-}" == "--extra-experimental-features" ]]' \
    '[[ "${2:-}" == "nix-command flakes" ]]' \
    '[[ "${3:-}" == run ]]' \
    '[[ "${4:-}" == "path:$REPO_DIR/nix#darwin-rebuild" ]]' \
    '[[ "${5:-}" == "--" ]]' \
    '[[ "${6:-}" == switch ]]' \
    '[[ "${7:-}" == "--flake" ]]' \
    '[[ "${8:-}" == "path:$REPO_DIR/nix#aarch64-darwin" ]]' \
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
    HOMEBREW_TEST_LOG="$bootstrap_log" \
    HOMEBREW_TEST_INSTALLER="$installer_script" \
    HOMEBREW_TEST_BREW_PATH="$mock_bin/brew" \
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
  assert [ -x "$mock_bin/brew" ]
  curl_line="$(awk '$1 == "curl" { print NR; exit }' "$bootstrap_log")"
  installer_line="$(awk '$1 == "installer" { print NR; exit }' "$bootstrap_log")"
  activation_line="$(awk '$1 == "nix" { print NR; exit }' "$bootstrap_log")"
  assert [ "$curl_line" -lt "$installer_line" ]
  assert [ "$installer_line" -lt "$activation_line" ]
  assert [ "$(awk '$1 == "installer" { count += 1 } END { print count + 0 }' "$bootstrap_log")" -eq 1 ]
  [[ ! -e "$nix_home/nix-darwin-config/flake.nix" ]]
  [[ "$(cksum "$REPO_DIR/nix/flake.nix")" == "$flake_hash" ]]
  [[ "$(cksum "$REPO_DIR/nix/flake.lock")" == "$lock_hash" ]]
  run grep -Fc -- 'darwinConfigurations."aarch64-darwin"' "$REPO_DIR/nix/flake.nix"
  assert_success
  assert_output "1"
  run grep -Fxc -- "--extra-experimental-features nix-command flakes run path:$REPO_DIR/nix#darwin-rebuild -- switch --flake path:$REPO_DIR/nix#aarch64-darwin --no-write-lock-file" \
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

@test "nix-darwin step fails clearly when the Homebrew installer fails" {
  local mock_bin="$BATS_TEST_TMPDIR/homebrew-installer-failure-bin"
  local nix_home="$BATS_TEST_TMPDIR/homebrew-installer-failure-home"
  local installer_log="$nix_home/installer.log"
  mkdir -p "$mock_bin" "$nix_home"
  create_homebrew_curl_mock "$mock_bin"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/bin:/bin" \
    HOMEBREW_TEST_LOG="$installer_log" \
    HOMEBREW_TEST_INSTALLER="exit 23" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      ensure_homebrew
      printf "%s\n" activated > "$HOME/activation-ran"
    '
  assert_failure
  assert_output_partial "Homebrew installer failed"
  assert [ ! -e "$nix_home/activation-ran" ]
}

@test "nix-darwin step rejects a Homebrew installer that leaves brew unavailable" {
  local mock_bin="$BATS_TEST_TMPDIR/homebrew-verification-bin"
  local nix_home="$BATS_TEST_TMPDIR/homebrew-verification-home"
  local installer_log="$nix_home/installer.log"
  mkdir -p "$mock_bin" "$nix_home"
  create_homebrew_curl_mock "$mock_bin"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/bin:/bin" \
    HOMEBREW_TEST_LOG="$installer_log" \
    HOMEBREW_TEST_INSTALLER='[[ "${NONINTERACTIVE:-}" == 1 ]]' \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      ensure_homebrew
      printf "%s\n" activated > "$HOME/activation-ran"
    '
  assert_failure
  assert_output_partial "brew was not found"
  assert [ ! -e "$nix_home/activation-ran" ]
}

@test "nix-darwin step preserves an explicit external flake without bootstrapping Homebrew" {
  local mock_bin="$BATS_TEST_TMPDIR/external-nix-darwin-bin"
  local nix_home="$BATS_TEST_TMPDIR/external-nix-darwin-home"
  local external_config="$BATS_TEST_TMPDIR/external-nix-darwin-flake"
  mkdir -p "$mock_bin" "$nix_home/mock-etc" "$external_config"
  external_config="$(cd "$external_config" && pwd -P)"
  : > "$external_config/flake.nix"

  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'if [[ "${1:-}" == "-m" ]]; then printf "%s\n" arm64; else printf "%s\n" Darwin; fi' \
    > "$mock_bin/uname"
  chmod +x "$mock_bin/uname"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\n" external-host' \
    > "$mock_bin/hostname"
  chmod +x "$mock_bin/hostname"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >> "$HOME/nix-darwin-nix-args"' \
    > "$mock_bin/nix"
  chmod +x "$mock_bin/nix"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'exec "$@"' \
    > "$mock_bin/sudo"
  chmod +x "$mock_bin/sudo"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\n" called > "$HOME/homebrew-installer-called"' \
    'exit 99' \
    > "$mock_bin/curl"
  chmod +x "$mock_bin/curl"

  run env HOME="$nix_home" PATH="$mock_bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" \
    NIX_DARWIN_CONFIG_DIR="$external_config" \
    NIX_DARWIN_HOSTNAME="external-test" \
    NIX_DARWIN_ETC_DIR="$nix_home/mock-etc" \
    NIX_DARWIN_STEP="$REPO_DIR/setup/macos/10-nix-darwin.sh" \
    bash -c '
      source "$NIX_DARWIN_STEP" help >/dev/null
      presteps
      run
    '
  assert_success
  assert [ ! -e "$nix_home/homebrew-installer-called" ]
  run grep -F -- "--flake path:$external_config#external-test" "$nix_home/nix-darwin-nix-args"
  assert_success
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
