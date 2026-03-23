#!/usr/bin/env bash

# Package manifests:
#   packages/fedora-atomic/rpm-ostree.txt
#   packages/fedora-atomic/flatpak.txt
#   packages/fedora-atomic/toolboxes.txt
#   packages/fedora-atomic/toolboxes/*.txt
#
# Export current Flatpaks:
#   flatpak list --app --columns=application | sort > packages/fedora-atomic/flatpak.txt
#
# Export toolbox package lists:
#   toolbox run cpp-dev  bash -lc 'dnf repoquery --userinstalled --qf "%{name}\n" | sort'
#   toolbox run latex    bash -lc 'dnf repoquery --userinstalled --qf "%{name}\n" | sort'
#   toolbox run mobile   bash -lc 'dnf repoquery --userinstalled --qf "%{name}\n" | sort'
#   toolbox run cli-dev  bash -lc 'dnf repoquery --userinstalled --qf "%{name}\n" | sort'

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$REPO_DIR/packages/fedora-atomic"

log() {
  printf '%s\n' "$*"
}

require_atomic_fedora() {
  if [[ ! -f /etc/fedora-release ]]; then
    log "error: this script is for Fedora"
    exit 1
  fi

  if ! command -v rpm-ostree >/dev/null 2>&1; then
    log "error: rpm-ostree not found; this does not look like Fedora Atomic"
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

layer_host_packages() {
  local file="$PKG_DIR/rpm-ostree.txt"
  mapfile -t packages < <(read_manifest "$file")

  if [[ ${#packages[@]} -eq 0 ]]; then
    log "No host packages to layer."
    return 0
  fi

  log "Layering host packages with rpm-ostree..."
  sudo rpm-ostree install "${packages[@]}"
  log "Host package layering complete. Reboot required to use newly layered packages."
}

setup_default_shell() {
  if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    log "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
    log "Shell changed. Log out/in or reboot for it to take effect."
  fi
}

install_zsh_plugins() {
  log "Installing zsh plugins..."
  mkdir -p "$HOME/.zsh"

  [[ -d "$HOME/.zsh/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions"

  [[ -d "$HOME/.zsh/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh/zsh-syntax-highlighting"

  [[ -d "$HOME/.zsh/zsh-autocomplete" ]] || \
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$HOME/.zsh/zsh-autocomplete"
}

setup_tealdeer_and_vim() {
  mkdir -p "$HOME/.config/tealdeer"
  tldr --update || true
  mkdir -p "$HOME/.vim/undo"
}

setup_flatpak() {
  log "Ensuring Flatpak + Flathub..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  flatpak update -y || true

  local file="$PKG_DIR/flatpak.txt"
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    log "Installing Flatpak: $pkg"
    flatpak install -y flathub "$pkg" || log "warn: failed/skipped flatpak $pkg"
  done < <(read_manifest "$file")
}

tb_run() {
  local name="$1"
  shift
  toolbox run --container "$name" bash -lc "$*"
}

create_toolboxes() {
  local file="$PKG_DIR/toolboxes.txt"
  while IFS= read -r box; do
    [[ -z "$box" ]] && continue
    toolbox create --container "$box" || true
  done < <(read_manifest "$file")
}

install_toolbox_packages() {
  local toolbox="$1"
  local manifest="$PKG_DIR/toolboxes/$toolbox.txt"

  [[ -f "$manifest" ]] || return 0

  mapfile -t packages < <(read_manifest "$manifest")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  log "Configuring toolbox: $toolbox"
  tb_run "$toolbox" "
    sudo dnf -y upgrade
    sudo dnf -y install ${packages[*]}
  "
}

configure_latex_toolbox_extras() {
  log "Installing LTEX LS in latex toolbox..."
  tb_run latex '
    mkdir -p "$HOME/.local/share/ltex-ls"
    cd "$HOME/.local/share/ltex-ls"
    LTX_URL="$(curl -sL https://api.github.com/repos/valentjn/ltex-ls/releases/latest | grep -Eo "https.*linux-x64\.tar\.gz" | head -n1)"
    [ -n "$LTX_URL" ] || exit 1
    wget -q "$LTX_URL" -O ltex-ls.tar.gz
    rm -rf ltex-ls && mkdir -p ltex-ls
    tar xzf ltex-ls.tar.gz -C ltex-ls --strip-components=1
    echo "LTEX LS installed at: $HOME/.local/share/ltex-ls/bin/ltex-ls"
  '
}

configure_mobile_toolbox_extras() {
  log "Installing extra mobile tools in mobile toolbox..."
  tb_run mobile '
    mkdir -p "$HOME/bin" "$HOME/opt"

    curl -fsSL -o "$HOME/bin/ktlint" \
      https://github.com/pinterest/ktlint/releases/latest/download/ktlint
    chmod +x "$HOME/bin/ktlint"

    cd "$HOME/opt"
    curl -fsSL -o portable_swiftlint_linux.zip \
      https://github.com/realm/SwiftLint/releases/latest/download/portable_swiftlint_linux.zip
    rm -rf swiftlint && mkdir swiftlint
    unzip -o portable_swiftlint_linux.zip -d swiftlint >/dev/null
    ln -sf "$HOME/opt/swiftlint/swiftlint" "$HOME/bin/swiftlint"
  '
}

configure_cli_dev_toolbox_extras() {
  log "Installing extra version managers in cli-dev toolbox..."
  tb_run cli-dev '
    if [ ! -d "$HOME/.jabba" ]; then
      curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
    fi

    if [ ! -d "$HOME/.pyenv" ]; then
      curl -fsSL https://pyenv.run | bash
    fi

    if [ ! -d "$HOME/.nvm" ]; then
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    fi
  '
}

print_reboot_notice() {
  log ""
  log "Fedora Atomic setup complete."
  log ""
  log "Host layered packages were requested via rpm-ostree."
  log "Please reboot to activate them:"
  log "  systemctl reboot"
}

main() {
  require_atomic_fedora

  log "Updating Atomic Fedora..."
  sudo rpm-ostree upgrade

  layer_host_packages
  setup_default_shell
  install_zsh_plugins
  setup_tealdeer_and_vim
  setup_flatpak

  log "Creating toolboxes..."
  create_toolboxes

  install_toolbox_packages cpp-dev
  install_toolbox_packages latex
  install_toolbox_packages mobile
  install_toolbox_packages cli-dev

  configure_latex_toolbox_extras
  configure_mobile_toolbox_extras
  configure_cli_dev_toolbox_extras

  print_reboot_notice
}

main "$@"