#!/usr/bin/env bats
# Fedora-specific checks for stable image traits and mocked setup integrations.

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

@test "dnf setup forwards every manifest package to dnf" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local dnf_args="$BATS_TEST_TMPDIR/dnf-args"
  mkdir -p "$mock_bin"
  create_mock_sudo "$mock_bin"
  cat > "$mock_bin/dnf" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$DNF_ARGS"
EOF
  chmod +x "$mock_bin/dnf"

  run env PATH="$mock_bin:$PATH" DNF_ARGS="$dnf_args" \
    "$REPO_DIR/setup.sh" --only fedora/03-dnf-packages.sh
  assert_success

  run grep -Fxq install "$dnf_args"
  assert_success
  run grep -Fxq -- -y "$dnf_args"
  assert_success
  while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
    if ! grep -Fxq -- "$package" "$dnf_args"; then
      _fail "dnf was not given manifest package: $package"
      return 1
    fi
  done < "$REPO_DIR/setup/fedora/dnf.txt"
}

@test "Flatpak runtime step adds Flathub when no remote is configured" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local flatpak_log="$BATS_TEST_TMPDIR/flatpak-log"
  local remote_marker="$BATS_TEST_TMPDIR/flathub-added"
  mkdir -p "$mock_bin"
  create_mock_sudo "$mock_bin"
  cat > "$mock_bin/flatpak" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FLATPAK_LOG"
if [[ "${1:-}" == remote-add ]]; then
  : > "$FLATPAK_REMOTE_MARKER"
fi
EOF
  chmod +x "$mock_bin/flatpak"

  run env PATH="$mock_bin:$PATH" FLATPAK_LOG="$flatpak_log" \
    FLATPAK_REMOTE_MARKER="$remote_marker" \
    "$REPO_DIR/setup.sh" --only fedora/05-flatpak-runtime.sh
  assert_success
  assert [ -f "$remote_marker" ]
  run grep -Fxq 'remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo' "$flatpak_log"
  assert_success
}

@test "Flatpak app step requests every manifest app" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local flatpak_installs="$BATS_TEST_TMPDIR/flatpak-installs"
  mkdir -p "$mock_bin"
  cat > "$mock_bin/flatpak" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  list) ;;
  install) printf '%s\n' "$*" >> "$FLATPAK_INSTALLS" ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$mock_bin/flatpak"

  run env PATH="$mock_bin:$PATH" FLATPAK_INSTALLS="$flatpak_installs" \
    "$REPO_DIR/setup.sh" --only fedora/06-flatpak-apps.sh
  assert_success
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
    if ! grep -Fxq -- "install -y flathub $app" "$flatpak_installs"; then
      _fail "flatpak install was not requested for manifest app: $app"
      return 1
    fi
  done < "$REPO_DIR/setup/fedora/flatpak.txt"
}

@test "Zsh plugin step clones all configured plugins" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local plugin_home="$BATS_TEST_TMPDIR/plugin-home"
  local git_clones="$BATS_TEST_TMPDIR/git-clones"
  mkdir -p "$mock_bin"
  cat > "$mock_bin/git" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == clone ]] || exit 2
printf '%s\t%s\n' "$2" "$3" >> "$GIT_CLONES"
mkdir -p "$3/.git"
EOF
  chmod +x "$mock_bin/git"

  run env PATH="$mock_bin:$PATH" HOME="$plugin_home" GIT_CLONES="$git_clones" \
    "$REPO_DIR/setup.sh" --only fedora/08-zsh-plugins.sh
  assert_success
  assert_dir_exists "$plugin_home/.zsh/zsh-autosuggestions/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-syntax-highlighting/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-autocomplete/.git"
}
