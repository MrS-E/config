#!/usr/bin/env bash
# Manjaro-specific helper library for setup steps.
#
# Sourced by Manjaro step scripts via:
#   source "$SCRIPT_DIR/common.bash"
# This file is NOT executable — the runner does not discover it as a step.
#
# Contains pacman, yay/AUR, service, and Manjaro-specific installer/downloader
# guards. Platform-neutral primitives live in setup/general/common.bash.

[[ -n "${_SETUP_MANJARO_COMMON:-}" ]] && return 0
_SETUP_MANJARO_COMMON=1

# Source general helpers if not already sourced.
if [[ -z "${_SETUP_GENERAL_COMMON:-}" ]]; then
  # shellcheck source=../general/common.bash
  source "$REPO_DIR/setup/general/common.bash"
fi

# Install pacman packages from a manifest. Uses --needed for idempotency.
# Installs packages one at a time so one missing/unavailable package does not
# block the rest.
pacman_install_from_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  local packages=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    packages+=("$pkg")
  done < "$file"

  [[ ${#packages[@]} -gt 0 ]] || { log "no packages in $file"; return 0; }

  local failed=0
  for pkg in "${packages[@]}"; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
      log "already installed: $pkg"
      continue
    fi
    if sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
      log "installed: $pkg"
    else
      log "warn: failed to install $pkg (may not exist in repos)"
      failed=1
    fi
  done
  return "$failed"
}

# Ensure yay (AUR helper) is installed. Idempotent.
# On Manjaro, yay is available in the official extra repo, so try pacman first.
# Falls back to the AUR build method for plain Arch or if the repo package is unavailable.
ensure_yay() {
  if command_exists yay; then
    log "yay already installed."
    return 0
  fi

  log "Installing yay..."

  # On Manjaro, yay is in the extra repo — try the fast path first.
  if sudo pacman -S --needed --noconfirm yay 2>/dev/null; then
    log "yay installed from official repos."
    return 0
  fi

  # Fall back to AUR build for plain Arch or if the repo package is unavailable.
  log "yay not in repos; building from AUR..."
  sudo pacman -S --needed --noconfirm base-devel git

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
}

# Install AUR packages from a manifest via yay. Uses --needed for idempotency.
aur_install_from_manifest() {
  local file="$1"
  [[ -f "$file" ]] || { log "manifest not found: $file"; return 0; }

  local packages=()
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    packages+=("$pkg")
  done < "$file"

  [[ ${#packages[@]} -gt 0 ]] || { log "no AUR packages in $file"; return 0; }

  ensure_yay
  yay -S --needed --noconfirm "${packages[@]}"
}

# Change default shell to zsh if not already set. Idempotent.
ensure_default_shell_zsh() {
  if ! command_exists zsh; then
    log "zsh not installed; skipping shell change."
    return 0
  fi
  if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
    log "Default shell is already zsh."
    return 0
  fi
  log "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)" || log "warn: chsh failed (may be expected in containers)"
  log "Shell changed. Log out/in for it to take effect."
}

# Install ZSH plugins via git clone. Idempotent.
install_zsh_plugins() {
  ensure_dir "$HOME/.zsh"

  ensure_git_clone https://github.com/zsh-users/zsh-autosuggestions.git   "$HOME/.zsh/zsh-autosuggestions"
  ensure_git_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"
  ensure_git_clone https://github.com/marlonrichert/zsh-autocomplete.git    "$HOME/.zsh/zsh-autocomplete"
}