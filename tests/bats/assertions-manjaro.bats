#!/usr/bin/env bats
# Manjaro-specific checks for the container image and mocked setup integrations.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

create_mock_sudo() {
  local mock_bin="$1"
  cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
  chmod +x "$mock_bin/sudo"
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
  # yay is not pre-installed; its bootstrap behavior is tested with mocks below.
  for pkg in zsh vim neovim git fzf flatpak openssh; do
    run pacman -Q "$pkg"
    assert_success "package $pkg should be installed"
  done
}

@test "yay bootstrap falls back to an AUR build when the repo package is unavailable" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local pacman_calls="$BATS_TEST_TMPDIR/pacman-calls"
  local git_calls="$BATS_TEST_TMPDIR/git-calls"
  local makepkg_calls="$BATS_TEST_TMPDIR/makepkg-calls"
  mkdir -p "$mock_bin"
  create_mock_sudo "$mock_bin"
  cat > "$mock_bin/pacman" <<'EOF'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "$PACMAN_CALLS"
case " $* " in
  *" yay "*) exit 1 ;;
  *) exit 0 ;;
esac
EOF
  cat > "$mock_bin/git" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == clone ]] || exit 2
printf '%s\n' "$*" >> "$GIT_CALLS"
mkdir -p "$3"
EOF
  cat > "$mock_bin/makepkg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MAKEPKG_CALLS"
EOF
  chmod +x "$mock_bin/pacman" "$mock_bin/git" "$mock_bin/makepkg"

  run env PATH="$mock_bin:$PATH" PACMAN_CALLS="$pacman_calls" \
    GIT_CALLS="$git_calls" MAKEPKG_CALLS="$makepkg_calls" \
    "$REPO_DIR/setup.sh" --only manjaro/03-yay-bootstrap.sh
  if [[ "$status" -ne 0 ]]; then
    printf '# setup output: %s\n' "${output:-<empty>}" >&3
    for call_log in "$pacman_calls" "$git_calls" "$makepkg_calls"; do
      if [[ -f "$call_log" ]]; then
        printf '# %s\n' "$call_log" >&3
        while IFS= read -r call; do
          printf '# %s\n' "$call" >&3
        done < "$call_log"
      else
        printf '# missing log: %s\n' "$call_log" >&3
      fi
    done
  fi
  assert_success
  run grep -Fxq 'pacman -S --needed --noconfirm yay' "$pacman_calls"
  assert_success
  run grep -Fxq 'pacman -S --needed --noconfirm base-devel git' "$pacman_calls"
  assert_success
  run grep -Fq 'clone https://aur.archlinux.org/yay.git' "$git_calls"
  assert_success
  run grep -Fxq -- '-si --noconfirm' "$makepkg_calls"
  assert_success
}

@test "AUR package step forwards every manifest package to yay" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local yay_args="$BATS_TEST_TMPDIR/yay-args"
  mkdir -p "$mock_bin"
  cat > "$mock_bin/yay" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$YAY_ARGS"
EOF
  chmod +x "$mock_bin/yay"

  run env PATH="$mock_bin:$PATH" YAY_ARGS="$yay_args" \
    "$REPO_DIR/setup.sh" --only manjaro/04-aur-packages.sh
  assert_success
  run grep -Fq -- '-S --needed --noconfirm' "$yay_args"
  assert_success
  while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
    if ! grep -Fq -- "$package" "$yay_args"; then
      _fail "yay was not given manifest package: $package"
      return 1
    fi
  done < "$REPO_DIR/setup/manjaro/aur.txt"
}

@test "Zsh plugin step clones all configured plugins" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local plugin_home="$BATS_TEST_TMPDIR/plugin-home"
  mkdir -p "$mock_bin"
  cat > "$mock_bin/git" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == clone ]] || exit 2
mkdir -p "$3/.git"
EOF
  chmod +x "$mock_bin/git"

  run env PATH="$mock_bin:$PATH" HOME="$plugin_home" \
    "$REPO_DIR/setup.sh" --only manjaro/06-zsh-plugins.sh
  assert_success
  assert_dir_exists "$plugin_home/.zsh/zsh-autosuggestions/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-syntax-highlighting/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-autocomplete/.git"
}

@test "manjaro step scripts are present and executable" {
  local dir="$REPO_DIR/setup/manjaro"
  assert [ -x "$dir/01-system-update.sh" ]
  assert [ -x "$dir/02-pacman-packages.sh" ]
  assert [ -x "$dir/03-yay-bootstrap.sh" ]
  assert [ -x "$dir/04-aur-packages.sh" ]
  assert [ -x "$dir/05-default-shell.sh" ]
}
