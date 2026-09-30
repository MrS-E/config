#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

NIX_TOOLBOX="nix"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists toolbox || die "toolbox not found"
}

help() {
  cat <<'EOF'
Install Nix inside a dedicated `nix` Toolbx in single-user mode. The immutable
Fedora Atomic host is not modified; enter the toolbox with `toolbox enter nix`
to use Nix. Idempotent: skips the installer when Nix is already in the toolbox.
EOF
}

ensure_nix_toolbox() {
  if toolbox list 2>/dev/null | grep -qF "$NIX_TOOLBOX"; then
    log "Nix toolbox already exists."
    return 0
  fi

  log "Creating Nix toolbox..."
  toolbox create --container "$NIX_TOOLBOX"
}

ensure_nix_dependencies() {
  if tb_run "$NIX_TOOLBOX" 'command -v curl >/dev/null && command -v tar >/dev/null && command -v xz >/dev/null'; then
    log "Nix toolbox dependencies already installed."
  else
    install_toolbox_packages "$NIX_TOOLBOX"
  fi
}

run() {
  ensure_nix_toolbox
  ensure_nix_dependencies

  log "Installing Nix in the $NIX_TOOLBOX toolbox..."
  tb_run "$NIX_TOOLBOX" '
    set -euo pipefail

    nix_installed() {
      command -v nix >/dev/null 2>&1 \
        || [[ -x /nix/var/nix/profiles/default/bin/nix ]] \
        || [[ -x "$HOME/.nix-profile/bin/nix" ]]
    }

    if nix_installed; then
      echo "Nix already installed in the toolbox."
    else
      curl --proto "=https" --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
    fi

    nix_config="$HOME/.config/nix/nix.conf"
    mkdir -p "$(dirname "$nix_config")"
    [[ -f "$nix_config" ]] || : > "$nix_config"
    grep -qxF -- "experimental-features = nix-command flakes" "$nix_config" \
      || printf "%s\\n" "experimental-features = nix-command flakes" >> "$nix_config"
  '
  log "Nix is available inside the $NIX_TOOLBOX toolbox."
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