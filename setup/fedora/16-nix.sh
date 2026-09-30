#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

NIX_DEFAULT_PROFILE="/nix/var/nix/profiles/default/bin/nix"
NIX_USER_PROFILE="$HOME/.nix-profile/bin/nix"
NIX_CONFIG_FILE="$HOME/.config/nix/nix.conf"
NIX_EXPERIMENTAL_FEATURES="experimental-features = nix-command flakes"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  if ! command_exists curl && ! command_exists wget; then
    die "required command not found: curl or wget"
  fi
}

help() {
  cat <<'EOF'
Install Nix in single-user mode with the official installer and enable the
nix-command and flakes experimental features. Idempotent: skips installation
when Nix is already installed and does not duplicate the configuration entry.
EOF
}

nix_installed() {
  command_exists nix \
    || [[ -x "$NIX_DEFAULT_PROFILE" ]] \
    || [[ -x "$NIX_USER_PROFILE" ]]
}

configure_nix() {
  ensure_dir "$(dirname "$NIX_CONFIG_FILE")"
  ensure_line_present "$NIX_CONFIG_FILE" "$NIX_EXPERIMENTAL_FEATURES"
}

run() {
  if nix_installed; then
    log "Nix already installed."
  else
    log "Installing Nix..."
    if command_exists curl; then
      curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
    else
      wget -O - https://nixos.org/nix/install | sh -s -- --no-daemon
    fi
    log "Nix installation complete. Restart the shell to load its environment."
  fi

  configure_nix
  log "Nix experimental features configured."
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