#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

NIX_DEFAULT_PROFILE="/nix/var/nix/profiles/default/bin/nix"
NIX_USER_PROFILE="$HOME/.nix-profile/bin/nix"
NIX_CONFIG_FILE="$HOME/.config/nix/nix.conf"
NIX_EXPERIMENTAL_FEATURES="experimental-features = nix-command flakes"

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
  require_command curl
}

help() {
  cat <<'EOF'
Install Nix using the official installer and enable the nix-command and flakes
experimental features. Idempotent: skips installation when Nix is already
installed and does not duplicate the configuration entry.
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
    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
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