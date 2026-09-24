#!/usr/bin/env bash
# Fedora-specific helper library for setup steps.
#
# Sourced by Fedora step scripts via:
#   source "$SCRIPT_DIR/common.bash"
# This file is NOT executable — the runner does not discover it as a step.
#
# Contains dnf, COPR, Flatpak, service, and Fedora-specific installer/downloader
# guards. Platform-neutral primitives live in setup/general/common.bash.

[[ -n "${_SETUP_FEDORA_COMMON:-}" ]] && return 0
_SETUP_FEDORA_COMMON=1

# Source general helpers if not already sourced.
if [[ -z "${_SETUP_GENERAL_COMMON:-}" ]]; then
  # shellcheck source=../general/common.bash
  source "$REPO_DIR/setup/general/common.bash"
fi

# Install dnf packages from a manifest file (one package per line, # comments).
# Uses `dnf install -y` which is a no-op for already-installed packages.
dnf_install_from_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  local packages=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    packages+=("$pkg")
  done < "$file"

  [[ ${#packages[@]} -gt 0 ]] || { log "no packages in $file"; return 0; }
  sudo dnf install -y "${packages[@]}"
}

# Enable COPR repos from a manifest file. Checks if already enabled first.
enable_copr_from_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  while IFS= read -r repo; do
    [[ -z "$repo" || "$repo" =~ ^[[:space:]]*# ]] && continue
    if dnf copr list --enabled 2>/dev/null | grep -qF "$repo"; then
      log "COPR already enabled: $repo"
      continue
    fi
    log "Enabling COPR: $repo"
    sudo dnf copr enable -y "$repo"
  done < "$file"
}

# Ensure Flatpak is installed and Flathub remote exists. Idempotent.
ensure_flatpak_runtime() {
  command_exists flatpak || sudo dnf install -y flatpak

  if flatpak remote-list 2>/dev/null | grep -qi flathub; then
    log "Flathub remote already exists."
    return 0
  fi
  log "Adding Flathub remote..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Install Flatpak apps from a manifest file. Skips already-installed apps.
flatpak_install_from_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  while IFS= read -r app; do
    [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
    if flatpak list --app 2>/dev/null | grep -qF "$app"; then
      log "Flatpak already installed: $app"
      continue
    fi
    log "Installing Flatpak: $app"
    flatpak install -y flathub "$app" || log "warn: flatpak failed/skipped: $app"
  done < "$file"
}

# Change default shell to zsh if not already set. Idempotent.
ensure_default_shell_zsh() {
  if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
    log "Default shell is already zsh."
    return 0
  fi
  log "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)" || log "warn: chsh failed (may be expected in containers)"
}

# Install ZSH plugins via git clone. Idempotent: skips existing directories.
install_zsh_plugins() {
  ensure_dir "$HOME/.zsh"

  ensure_git_clone https://github.com/zsh-users/zsh-autosuggestions.git   "$HOME/.zsh/zsh-autosuggestions"
  ensure_git_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"
  ensure_git_clone https://github.com/marlonrichert/zsh-autocomplete.git    "$HOME/.zsh/zsh-autocomplete"
}

# Create tealdeer config dir and update tldr cache. Idempotent.
setup_tealdeer() {
  ensure_dir "$HOME/.config/tealdeer"
  if command_exists tldr; then
    tldr --update 2>/dev/null || true
  fi
}