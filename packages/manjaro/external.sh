#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '%s\n' "$*"
}

# --- JetBrains Toolbox ---
install_jetbrains_toolbox() {
  local version="3.0.1.59888"
  local base_dir="$HOME/.config/jetbrains"
  local archive="$base_dir/jetbrains-toolbox-$version.tar.gz"
  local unpacked="$base_dir/jetbrains-toolbox-$version"
  local bin="$unpacked/bin/jetbrains-toolbox"

  mkdir -p "$base_dir"

  if [[ ! -x "$bin" ]]; then
    log "Installing JetBrains Toolbox..."
    wget -O "$archive" "https://download.jetbrains.com/toolbox/jetbrains-toolbox-$version.tar.gz"
    tar -xzf "$archive" -C "$base_dir"
  fi

  nohup "$bin" >/dev/null 2>&1 &
}

# --- Jabba ---
install_jabba() {
  if [[ ! -d "$HOME/.jabba" ]]; then
    log "Installing jabba..."
    curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
  fi
}

# --- Joplin ---
install_joplin() {
  if ! command -v joplin >/dev/null 2>&1; then
    log "Installing Joplin..."
    wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
  fi
}

# --- Cisco Secure Client (manual) ---
print_cisco_note() {
  log ""
  log "Cisco Secure Client requires manual install:"
  log "   https://servicedesk.zhaw.ch/tas/public/ssp/content/search?q=KI%201747"
}

# --- Celeste (Flatpak alternative) ---
install_celeste_note() {
  log ""
  log "Celeste available via Flatpak or:"
  log "   https://github.com/hwittenborn/celeste"
}

main() {
  install_jetbrains_toolbox
  install_jabba
  install_joplin
  install_celeste_note
  print_cisco_note

  log ""
  log "✅ External setup complete."
}

main "$@"