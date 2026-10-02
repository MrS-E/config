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

@test "zshrc initializes Starship after adding user-local bin to PATH" {
  local test_home="$BATS_TEST_TMPDIR/home"
  local fake_bin="$test_home/.local/bin"
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  mkdir -p "$fake_bin" "$mock_bin"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'if [ "$1" = "-n" ] && [ "$2" = "hw.memsize" ]; then' \
    '  printf "%s\\n" 17179869184' \
    '  exit 0' \
    'fi' \
    'exit 1' \
    > "$mock_bin/sysctl"
  chmod +x "$mock_bin/sysctl"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'test "$1" = init && test "$2" = zsh || exit 2' \
    'printf "%s\\n" "STARSHIP_TEST_INITIALIZED=yes"' \
    > "$fake_bin/starship"
  chmod +x "$fake_bin/starship"

  run env HOME="$test_home" PATH="$mock_bin:/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" zsh -f -c '
      source "$REPO_DIR/zshrc"
      if [[ "${STARSHIP_TEST_INITIALIZED:-}" != yes ]]; then
        print -r -- "PATH=$PATH"
        print -r -- "starship=$(command -v starship || print missing)"
        print -r -- "initialized=${STARSHIP_TEST_INITIALIZED:-unset}"
        exit 1
      fi
    '

  assert_success
}

@test "zshrc does not initialize Homebrew or add its prefix" {
  run grep -nE 'brew shellenv|/opt/homebrew|/usr/local/bin/brew' "$REPO_DIR/zshrc"
  assert_failure
}

@test "nix-system-update activates Home Manager without nix-darwin" {
  local test_home="$BATS_TEST_TMPDIR/home"
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local activation_dir="$BATS_TEST_TMPDIR/home-manager"
  local nix_arguments="$BATS_TEST_TMPDIR/nix-arguments"
  local activation_marker="$BATS_TEST_TMPDIR/activation-marker"
  mkdir -p "$mock_bin" "$activation_dir"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'case "$1" in' \
    '  -s) printf "%s\\n" Darwin ;;' \
    '  -m) printf "%s\\n" arm64 ;;' \
    '  *) exit 1 ;;' \
    'esac' \
    > "$mock_bin/uname"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'if [ "$1" = "-n" ] && [ "$2" = "hw.memsize" ]; then' \
    '  printf "%s\\n" 17179869184' \
    '  exit 0' \
    'fi' \
    'exit 1' \
    > "$mock_bin/sysctl"
  cat > "$mock_bin/nix" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" > "$NIX_TEST_ARGUMENTS"
printf '%s\n' "$NIX_TEST_ACTIVATION_PACKAGE"
EOF
  cat > "$activation_dir/activate" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' activated > "$NIX_TEST_ACTIVATION_MARKER"
EOF
  chmod +x "$mock_bin/uname" "$mock_bin/sysctl" "$mock_bin/nix" "$activation_dir/activate"

  run env HOME="$test_home" PATH="$mock_bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" \
    NIX_TEST_ARGUMENTS="$nix_arguments" \
    NIX_TEST_ACTIVATION_PACKAGE="$activation_dir" \
    NIX_TEST_ACTIVATION_MARKER="$activation_marker" \
    zsh -f -c '
      unset NIX_DARWIN_CONFIG_DIR NIX_DARWIN_HOSTNAME
      source "$REPO_DIR/zshrc"
      nix-system-update
      [[ -f "$NIX_TEST_ACTIVATION_MARKER" ]] || exit 1
      command grep -Fq -- "path:$REPO_DIR/nix#darwinConfigurations.aarch64-darwin.config.home-manager.users.\"$(id -un)\".home.activationPackage" "$NIX_TEST_ARGUMENTS" || exit 1
      ! command grep -Fq -- "darwin-rebuild" "$NIX_TEST_ARGUMENTS"
    '

  assert_success
}

@test "zshrc initializes storage for recent directories" {
  local test_home="$BATS_TEST_TMPDIR/home"
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  mkdir -p "$mock_bin"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'if [ "$1" = "-n" ] && [ "$2" = "hw.memsize" ]; then' \
    '  printf "%s\\n" 17179869184' \
    '  exit 0' \
    'fi' \
    'exit 1' \
    > "$mock_bin/sysctl"
  printf '%s\n' '#!/usr/bin/env sh' 'exit 0' > "$mock_bin/tailscale"
  chmod +x "$mock_bin/sysctl" "$mock_bin/tailscale"

  run env HOME="$test_home" PATH="$mock_bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" zsh -f -c '
      unset XDG_DATA_HOME
      source "$REPO_DIR/zshrc"
      [[ "$XDG_DATA_HOME" = "$HOME/.local/share" && -d "$XDG_DATA_HOME/zsh" ]]
    '

  assert_success
}

@test "zshrc does not invoke the Tailscale GUI binary for completion on macOS" {
  local test_home="$BATS_TEST_TMPDIR/home"
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local tailscale_marker="$BATS_TEST_TMPDIR/tailscale-was-invoked"
  mkdir -p "$mock_bin"

  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'case "$1" in' \
    '  -s) printf "%s\\n" Darwin ;;' \
    '  -m) printf "%s\\n" arm64 ;;' \
    '  *) exit 1 ;;' \
    'esac' \
    > "$mock_bin/uname"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'printf "%s\\n" invoked > "$TAILSCALE_MARKER"' \
    > "$mock_bin/tailscale"
  printf '%s\n' \
    '#!/usr/bin/env sh' \
    'if [ "$1" = "-n" ] && [ "$2" = "hw.memsize" ]; then' \
    '  printf "%s\\n" 17179869184' \
    '  exit 0' \
    'fi' \
    'exit 1' \
    > "$mock_bin/sysctl"
  chmod +x "$mock_bin/uname" "$mock_bin/tailscale" "$mock_bin/sysctl"

  run env HOME="$test_home" PATH="$mock_bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin" \
    REPO_DIR="$REPO_DIR" TAILSCALE_MARKER="$tailscale_marker" zsh -f -c '
      source "$REPO_DIR/zshrc"
      [[ ! -e "$TAILSCALE_MARKER" ]]
    '

  assert_success
}