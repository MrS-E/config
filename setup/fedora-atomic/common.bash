#!/usr/bin/env bash
# Fedora Atomic-specific helper library for setup steps.
#
# Sourced by Fedora Atomic step scripts via:
#   source "$SCRIPT_DIR/common.bash"
# This file is NOT executable — the runner does not discover it as a step.
#
# Contains rpm-ostree, Flatpak, toolbox, and Atomic-specific installer/downloader
# guards. Platform-neutral primitives live in setup/general/common.bash.

[[ -n "${_SETUP_FEDORA_ATOMIC_COMMON:-}" ]] && return 0
_SETUP_FEDORA_ATOMIC_COMMON=1

# Source general helpers if not already sourced.
if [[ -z "${_SETUP_GENERAL_COMMON:-}" ]]; then
  # shellcheck source=../general/common.bash
  source "$REPO_DIR/setup/general/common.bash"
fi

# Layer host packages from a manifest via rpm-ostree. Idempotent: rpm-ostree
# install is a no-op for already-layered packages.
layer_host_packages() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  local packages=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    packages+=("$pkg")
  done < "$file"

  [[ ${#packages[@]} -gt 0 ]] || { log "no host packages to layer."; return 0; }

  log "Layering host packages with rpm-ostree..."
  sudo rpm-ostree install "${packages[@]}"
  log "Host package layering complete. Reboot required to use newly layered packages."
}

# Ensure Flatpak is installed and Flathub remote exists. Idempotent.
ensure_flatpak_remote() {
  command_exists flatpak || sudo rpm-ostree install flatpak 2>/dev/null || sudo dnf install -y flatpak 2>/dev/null || true

  if flatpak remote-list 2>/dev/null | grep -qi flathub; then
    log "Flathub remote already exists."
    return 0
  fi
  log "Adding Flathub remote..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  flatpak update -y 2>/dev/null || true
}

# Install Flatpak apps from a manifest. Skips already-installed apps.
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
    flatpak install -y flathub "$app" || log "warn: failed/skipped flatpak $app"
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
  log "Shell changed. Log out/in or reboot for it to take effect."
}

# Install ZSH plugins via git clone. Idempotent.
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

# Run a command inside a toolbox container.
tb_run() {
  local name="$1"
  shift
  toolbox run --container "$name" bash -lc "$*"
}

# Create toolboxes from a manifest. Skips already-existing toolboxes.
create_toolboxes() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  while IFS= read -r box; do
    [[ -z "$box" || "$box" =~ ^[[:space:]]*# ]] && continue
    if toolbox list 2>/dev/null | grep -qF "$box"; then
      log "Toolbox already exists: $box"
      continue
    fi
    log "Creating toolbox: $box"
    toolbox create --container "$box" || log "warn: toolbox create failed for $box"
  done < "$file"
}

# Install packages inside a toolbox from its manifest.
install_toolbox_packages() {
  local toolbox="$1"
  local manifest="$SCRIPT_DIR/toolboxes/$toolbox.txt"

  [[ -f "$manifest" ]] || { log "no manifest for toolbox $toolbox"; return 0; }

  local packages=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    packages+=("$pkg")
  done < "$manifest"

  [[ ${#packages[@]} -gt 0 ]] || { log "no packages for toolbox $toolbox"; return 0; }

  log "Installing packages in toolbox: $toolbox"
  tb_run "$toolbox" "
    sudo dnf -y upgrade
    sudo dnf -y install ${packages[*]}
  "
}