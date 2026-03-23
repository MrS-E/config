#!/usr/bin/env bash
set -euo pipefail

# Package manifests:
#   packages/manjaro/pacman.txt
#   packages/manjaro/aur.txt
#   packages/manjaro/external.txt
#
# Export explicitly installed pacman packages:
#   pacman -Qqe | sort > packages/manjaro/pacman.txt
#
# Export foreign/AUR packages:
#   pacman -Qqm | sort > packages/manjaro/aur.txt

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$REPO_DIR/packages/manjaro"

log() {
  printf '%s\n' "$*"
}

require_manjaro() {
  if [[ ! -f /etc/manjaro-release ]]; then
    log "error: this script is for Manjaro"
    exit 1
  fi

  if [[ $EUID -eq 0 ]]; then
    log "error: run as a regular user, not root"
    exit 1
  fi
}

read_manifest() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -vE '^\s*$|^\s*#' "$file"
}

install_pacman_packages() {
  local file="$PKG_DIR/pacman.txt"
  mapfile -t packages < <(read_manifest "$file")

  [[ ${#packages[@]} -gt 0 ]] || {
    log "No pacman packages to install."
    return 0
  }

  log "Updating system..."
  sudo pacman -Syu --noconfirm

  log "Installing pacman packages..."
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  log "Installing yay..."
  sudo pacman -S --needed --noconfirm base-devel git

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
}

install_aur_packages() {
  local file="$PKG_DIR/aur.txt"
  mapfile -t packages < <(read_manifest "$file")

  [[ ${#packages[@]} -gt 0 ]] || {
    log "No AUR packages to install."
    return 0
  }

  ensure_yay

  log "Installing AUR packages..."
  yay -S --needed --noconfirm "${packages[@]}"
}

setup_zsh_plugins() {
  log "Installing zsh plugins..."
  mkdir -p "$HOME/.zsh"

  [[ -d "$HOME/.zsh/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions"

  [[ -d "$HOME/.zsh/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"

  [[ -d "$HOME/.zsh/zsh-autocomplete" ]] || \
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.zsh/zsh-autocomplete"
}

setup_default_shell() {
  if command -v zsh >/dev/null 2>&1 && [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
    log "Shell changed. Log out/in for it to take effect."
  fi
}

setup_printer() {
  if systemctl list-unit-files | grep -q '^cups\.service'; then
    log "Enabling cups..."
    sudo systemctl enable --now cups.service || true
  fi
}

setup_firewall() {
  if pacman -Q nftables >/dev/null 2>&1; then
    sudo systemctl enable --now nftables || true
  fi

  if command -v ufw >/dev/null 2>&1; then
    sudo ufw --force enable || true
  fi
}

setup_clamav() {
  if systemctl list-unit-files | grep -q '^clamav-freshclam\.service'; then
    sudo systemctl enable --now clamav-freshclam.service || true
  fi
}

run_external_scripts() {
  local dir="$PKG_DIR/external"

  [[ -d "$dir" ]] || {
    log "No external directory found."
    return 0
  }

  shopt -s nullglob
  local scripts=("$dir"/*.sh)
  shopt -u nullglob

  [[ ${#scripts[@]} -gt 0 ]] || {
    log "No external scripts to run."
    return 0
  }

  log "Running external setup scripts..."
  local script
  for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
      log "-> $(basename "$script")"
      "$script"
    else
      log "skip: not executable: $script"
    fi
  done
}

main() {
  require_manjaro
  install_pacman_packages
  install_aur_packages
  setup_zsh_plugins
  setup_default_shell
  setup_printer
  setup_firewall
  setup_clamav
  run_external_scripts
  log ""
  log "Manjaro setup complete."
}

main "$@"