#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '%s\n' "$*"
}

link_path() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    log "skip: source does not exist: $src"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    ln -sfn "$src" "$dest"
    log "linked: $dest -> $src"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    log "backup: $dest -> $backup"
  fi

  ln -sfn "$src" "$dest"
  log "linked: $dest -> $src"
}

setup_symlinks() {
  log "Setting up symlinks..."

  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.ssh"

  link_path "$REPO_DIR/zshrc" "$HOME/.zshrc"
  link_path "$REPO_DIR/vimrc" "$HOME/.vimrc"
  link_path "$REPO_DIR/gitconfig" "$HOME/.gitconfig"

  link_path "$REPO_DIR/vim" "$HOME/.vim"
  link_path "$REPO_DIR/nvim" "$HOME/.config/nvim"
  link_path "$REPO_DIR/lazygit" "$HOME/.config/lazygit"

  [[ -d "$REPO_DIR/ghostty" ]] && link_path "$REPO_DIR/ghostty" "$HOME/.config/ghostty"
  [[ -d "$REPO_DIR/Nextcloud" ]] && link_path "$REPO_DIR/Nextcloud" "$HOME/.config/Nextcloud"

  [[ -f "$REPO_DIR/ssh/config" ]] && link_path "$REPO_DIR/ssh/config" "$HOME/.ssh/config"
  [[ -f "$REPO_DIR/ssh/known_hosts" ]] && link_path "$REPO_DIR/ssh/known_hosts" "$HOME/.ssh/known_hosts"

  chmod 700 "$HOME/.ssh" || true
}

run_platform_setup() {
  case "$(uname -s)" in
    Darwin)
      if [[ -x "$REPO_DIR/setup.macos.sh" ]]; then
        "$REPO_DIR/setup.macos.sh"
      else
        log "warn: setup.macos.sh not found or not executable"
      fi
      ;;
    Linux)
      if [[ -x "$REPO_DIR/setup.fedora.sh" ]]; then
        "$REPO_DIR/setup.fedora.sh"
      else
        log "warn: no Linux-specific setup script selected"
      fi
      ;;
    *)
      log "warn: unsupported OS: $(uname -s)"
      ;;
  esac
}

main() {
  log "Starting base setup..."
  setup_symlinks
  run_platform_setup
  log "Base setup complete."
}

main "$@"