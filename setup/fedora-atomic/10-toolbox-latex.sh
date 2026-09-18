#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

LTEX_DIR='$HOME/.local/share/ltex-ls/bin/ltex-ls'

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists toolbox || die "toolbox not found"
}

help() {
  cat <<'EOF'
Install LTEX LS (LanguageTool for LaTeX) inside the latex toolbox.
Idempotent: skips when the ltex-ls binary already exists in the toolbox.
EOF
}

run() {
  log "Checking LTEX LS in latex toolbox..."
  if tb_run latex "[ -x $LTEX_DIR ]" 2>/dev/null; then
    log "LTEX LS already installed in latex toolbox."
    return 0
  fi

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

case "${1:-}" in
  presteps) presteps ;;
  help) help ;;
  run) run ;;
  *)
    printf 'usage: %s {presteps|help|run}\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac