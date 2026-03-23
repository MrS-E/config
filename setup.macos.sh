#!/usr/bin/env bash

# =========================================================
#  Package management (Brewfile)
#
# Brewfile location:
#   packages/macos/Brewfile
#
# Export current system:
#
#   brew bundle dump --describe \
#     --file=packages/macos/Brewfile \
#     --force
#
# Check differences:
#   brew bundle check --file=packages/macos/Brewfile
#
# =========================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$REPO_DIR/packages/macos/Brewfile"

log() {
  printf '%s\n' "$*"
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log "error: setup.macos.sh must be run on macOS"
    exit 1
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed."
    return 0
  fi

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    log "error: Homebrew installation finished but brew is still not on PATH"
    exit 1
  fi
}

ensure_ssh_agent() {
  if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    log "Starting ssh-agent..."
    eval "$(ssh-agent -s)" >/dev/null
  else
    log "ssh-agent already running."
  fi
}

add_ssh_keys_to_keychain() {
  local ssh_dir="$HOME/.ssh"

  [[ -d "$ssh_dir" ]] || return 0

  while IFS= read -r -d '' key; do
    case "$(basename "$key")" in
      *.pub|known_hosts|config)
        continue
        ;;
    esac

    log "Adding SSH key to Apple keychain: $key"
    ssh-add --apple-use-keychain "$key" >/dev/null 2>&1 || true
  done < <(find "$ssh_dir" -type f -perm 600 -print0 2>/dev/null)
}

install_brew_packages() {
  if [[ -f "$BREWFILE" ]]; then
    log "Installing Homebrew packages from Brewfile..."
    brew bundle --file="$BREWFILE"
  else
    log "warn: no Brewfile found at $BREWFILE"
  fi
}

install_vim_theme() {
  local theme_dir="$HOME/.vim/pack/themes/start/dracula"
  mkdir -p "$(dirname "$theme_dir")"

  if [[ ! -d "$theme_dir" ]]; then
    log "Installing Dracula vim theme..."
    git clone https://github.com/dracula/vim.git "$theme_dir"
  else
    log "Dracula vim theme already installed."
  fi
}

main() {
  ensure_macos
  log "Starting macOS setup..."
  ensure_homebrew
  ensure_ssh_agent
  add_ssh_keys_to_keychain
  install_brew_packages
  install_vim_theme
  log "macOS setup complete."
}

main "$@"