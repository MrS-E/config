#!/usr/bin/env bash

# =========================================================
# Package management
#
# Edit packages in:
#   packages/fedora/dnf.txt      → dnf packages
#   packages/fedora/flatpak.txt  → flatpak apps
#   packages/fedora/copr.txt     → copr repos
#
# Export current system:
#
#   # DNF (user-installed packages)
#   dnf repoquery --userinstalled --qf "%{name}\n" | sort > packages/fedora/dnf.txt
#
#   # Flatpak
#   flatpak list --app --columns=application | sort > packages/fedora/flatpak.txt
#
#   # COPR repos
#   dnf repolist --enabled | grep copr: | awk '{print $1}' | sed 's|copr:copr.fedorainfracloud.org:||' | sort > packages/fedora/copr.txt
#
# =========================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$REPO_DIR/packages/fedora"

log() {
  printf '%s\n' "$*"
}

require_fedora() {
  if [[ ! -f /etc/fedora-release ]]; then
    log "error: this script is for Fedora"
    exit 1
  fi

  if command -v rpm-ostree >/dev/null 2>&1; then
    log "error: rpm-ostree detected; use your Atomic-specific setup instead"
    exit 1
  fi

  if [[ $EUID -eq 0 ]]; then
    log "error: run as regular user, not root"
    exit 1
  fi
}

dnf_install_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  mapfile -t packages < <(grep -vE '^\s*$|^\s*#' "$file")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  sudo dnf install -y "${packages[@]}"
}

enable_copr_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" =~ ^[[:space:]]*# ]] && continue
    sudo dnf copr enable -y "$repo"
  done < "$file"
}

install_flatpaks_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  sudo dnf install -y flatpak

  if ! flatpak remote-list | grep -qi flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi

  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    flatpak install -y flathub "$pkg" || log "warn: flatpak failed/skipped: $pkg"
  done < "$file"
}

setup_shell() {
  mkdir -p "$HOME/.config/tealdeer"
  tldr --update || true
  mkdir -p "$HOME/.vim/undo"

  if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
  fi
}

install_zsh_plugins() {
  mkdir -p "$HOME/.zsh"

  [[ -d "$HOME/.zsh/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions"

  [[ -d "$HOME/.zsh/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"

  [[ -d "$HOME/.zsh/zsh-autocomplete" ]] || \
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.zsh/zsh-autocomplete"
}

install_toolbox() {
  local version="3.0.1.59888"
  local base_dir="$HOME/.config/jetbrains"
  local archive="$base_dir/jetbrains-toolbox-$version.tar.gz"
  local unpacked="$base_dir/jetbrains-toolbox-$version"
  local bin="$unpacked/bin/jetbrains-toolbox"

  mkdir -p "$base_dir"

  if [[ ! -x "$bin" ]]; then
    wget -O "$archive" "https://download.jetbrains.com/toolbox/jetbrains-toolbox-$version.tar.gz"
    tar -xzf "$archive" -C "$base_dir"
  fi

  nohup "$bin" >/dev/null 2>&1 &
}

install_proton_bridge() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  pushd "$tmpdir" >/dev/null
  wget https://proton.me/download/bridge/protonmail-bridge-3.13.0-1.x86_64.rpm
  sudo dnf install -y ./protonmail-bridge-3.13.0-1.x86_64.rpm
  popd >/dev/null
}

setup_services() {
  sudo systemctl enable --now tailscaled
  sudo tailscale set --operator="$USER" || true
}

main() {
  require_fedora

  log "Updating system..."
  sudo dnf -y upgrade --refresh

  log "Configuring extra repos..."
  [[ -x "$PKG_DIR/repos.sh" ]] && "$PKG_DIR/repos.sh"

  log "Installing base packages..."
  dnf_install_from_file "$PKG_DIR/dnf.txt"

  log "Enabling COPRs..."
  enable_copr_from_file "$PKG_DIR/copr.txt"

  log "Installing COPR packages..."
  sudo dnf install -y lazygit scrcpy codium steam proton-vpn-gnome-desktop

  log "Installing Flatpaks..."
  install_flatpaks_from_file "$PKG_DIR/flatpak.txt"

  setup_shell
  install_zsh_plugins
  install_toolbox
  install_proton_bridge
  setup_services

  log "Fedora setup complete."
}

main "$@"