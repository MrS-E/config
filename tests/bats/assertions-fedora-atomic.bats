#!/usr/bin/env bats
# Fedora Atomic-specific checks for the mocked container and setup integrations.

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

@test "host package step forwards every manifest package to rpm-ostree" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local rpm_ostree_args="$BATS_TEST_TMPDIR/rpm-ostree-args"
  mkdir -p "$mock_bin"
  create_mock_sudo "$mock_bin"
  cat > "$mock_bin/rpm-ostree" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$RPM_OSTREE_ARGS"
EOF
  chmod +x "$mock_bin/rpm-ostree"

  run env PATH="$mock_bin:$PATH" RPM_OSTREE_ARGS="$rpm_ostree_args" \
    "$REPO_DIR/setup.sh" --only fedora-atomic/02-host-packages.sh
  assert_success
  run grep -Fxq install "$rpm_ostree_args"
  assert_success
  while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
    if ! grep -Fxq -- "$package" "$rpm_ostree_args"; then
      _fail "rpm-ostree was not given manifest package: $package"
      return 1
    fi
  done < "$REPO_DIR/setup/fedora-atomic/rpm-ostree.txt"
}

@test "Flatpak remote step adds Flathub when no remote is configured" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  local flatpak_log="$BATS_TEST_TMPDIR/flatpak-log"
  local remote_marker="$BATS_TEST_TMPDIR/flathub-added"
  mkdir -p "$mock_bin"
  create_mock_sudo "$mock_bin"
  cat > "$mock_bin/flatpak" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FLATPAK_LOG"
case "${1:-}" in
  remote-list|update) ;;
  remote-add) : > "$FLATPAK_REMOTE_MARKER" ;;
  *) exit 2 ;;
esac
EOF
  chmod +x "$mock_bin/flatpak"

  run env PATH="$mock_bin:$PATH" FLATPAK_LOG="$flatpak_log" \
    FLATPAK_REMOTE_MARKER="$remote_marker" \
    "$REPO_DIR/setup.sh" --only fedora-atomic/06-flatpak-remote.sh
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
    "$REPO_DIR/setup.sh" --only fedora-atomic/07-flatpak-apps.sh
  assert_success
  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
    if ! grep -Fxq -- "install -y flathub $app" "$flatpak_installs"; then
      _fail "flatpak install was not requested for manifest app: $app"
      return 1
    fi
  done < "$REPO_DIR/setup/fedora-atomic/flatpak.txt"
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
    "$REPO_DIR/setup.sh" --only fedora-atomic/04-zsh-plugins.sh
  assert_success
  assert_dir_exists "$plugin_home/.zsh/zsh-autosuggestions/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-syntax-highlighting/.git"
  assert_dir_exists "$plugin_home/.zsh/zsh-autocomplete/.git"
}
