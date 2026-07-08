#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

presteps() {
  require_command ln
  require_command mkdir
}

help() {
  cat <<'EOF'
Symlink dotfiles (zshrc, vimrc, gitconfig, vim/, nvim/, lazygit/, junie/,
ghostty/, Nextcloud/, ssh config) into $HOME. Idempotent: existing correct
symlinks are left untouched; pre-existing non-symlinks are backed up once.
EOF
}

run() {
  log "Setting up symlinks..."

  ensure_dir "$HOME/.config"
  # ensure_dir "$HOME/.ssh"

  ensure_symlink "$REPO_DIR/zshrc"     "$HOME/.zshrc"
  ensure_symlink "$REPO_DIR/vimrc"     "$HOME/.vimrc"
  ensure_symlink "$REPO_DIR/gitconfig" "$HOME/.gitconfig"

  ensure_symlink "$REPO_DIR/vim"      "$HOME/.vim"
  ensure_symlink "$REPO_DIR/nvim"     "$HOME/.config/nvim"
  ensure_symlink "$REPO_DIR/lazygit"  "$HOME/.config/lazygit"
  ensure_symlink "$REPO_DIR/ssh"      "$HOME/.ssh"

  ensure_symlink "$REPO_DIR/junie" "$HOME/.junie"

  [[ -d "$REPO_DIR/ghostty" ]]   && ensure_symlink "$REPO_DIR/ghostty"   "$HOME/.config/ghostty"
  [[ -d "$REPO_DIR/Nextcloud" ]] && ensure_symlink "$REPO_DIR/Nextcloud" "$HOME/.config/Nextcloud"

  # [[ -f "$REPO_DIR/ssh/config" ]]       && ensure_symlink "$REPO_DIR/ssh/config"       "$HOME/.ssh/config"
  # [[ -f "$REPO_DIR/ssh/known_hosts" ]] && ensure_symlink "$REPO_DIR/ssh/known_hosts" "$HOME/.ssh/known_hosts"

  chmod 700 "$HOME/.ssh" || true
}

case "${1:-}" in
  presteps) presteps ;;
  help) help ;;
  run) run ;;
  *)
    printf 'usage: %s {presteps|help|run}\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
