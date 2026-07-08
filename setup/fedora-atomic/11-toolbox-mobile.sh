#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  command_exists toolbox || die "toolbox not found"
}

help() {
  cat <<'EOF'
Install ktlint and SwiftLint inside the mobile toolbox.
Idempotent: skips when the tools already exist in the toolbox.
EOF
}

run() {
  log "Installing mobile tools in mobile toolbox..."

  tb_run mobile '
    mkdir -p "$HOME/bin" "$HOME/opt"

    if [ ! -x "$HOME/bin/ktlint" ]; then
      curl -fsSL -o "$HOME/bin/ktlint" \
        https://github.com/pinterest/ktlint/releases/latest/download/ktlint
      chmod +x "$HOME/bin/ktlint"
    fi

    if [ ! -x "$HOME/bin/swiftlint" ]; then
      cd "$HOME/opt"
      curl -fsSL -o portable_swiftlint_linux.zip \
        https://github.com/realm/SwiftLint/releases/latest/download/portable_swiftlint_linux.zip
      rm -rf swiftlint && mkdir swiftlint
      unzip -o portable_swiftlint_linux.zip -d swiftlint >/dev/null
      ln -sf "$HOME/opt/swiftlint/swiftlint" "$HOME/bin/swiftlint"
    fi
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