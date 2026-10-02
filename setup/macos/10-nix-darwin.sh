#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

# nix-darwin is the macOS system manager for launchd daemons.
NIX_DEFAULT_PROFILE="/nix/var/nix/profiles/default/bin/nix"
NIX_USER_PROFILE="$HOME/.nix-profile/bin/nix"
NIX_DARWIN_CONFIG_DIR_EXPLICIT=0
if [[ -n "${NIX_DARWIN_CONFIG_DIR:-}" ]]; then
  NIX_DARWIN_CONFIG_DIR_EXPLICIT=1
fi
NIX_DARWIN_CONFIG_DIR="${NIX_DARWIN_CONFIG_DIR:-$REPO_DIR/nix}"
NIX_DARWIN_HOSTNAME="${NIX_DARWIN_HOSTNAME:-}"
NIX_DARWIN_ETC_DIR="${NIX_DARWIN_ETC_DIR:-/etc}"
NIX_EXPERIMENTAL_FEATURES=(--extra-experimental-features "nix-command flakes")

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
  nix_available || die "required command not found: nix"
  require_command sudo
  require_command hostname
}

help() {
  cat <<'EOF'
Activate this repository's pinned nix-darwin configuration. Set
NIX_DARWIN_CONFIG_DIR to select an external flake; set NIX_DARWIN_HOSTNAME to
select its darwinConfigurations output. Flakes are never initialized, edited,
or locked by this step. An existing ~/nix-darwin-config/flake.nix must be
selected explicitly. Existing unmanaged /etc files are backed up before
activation; skip this step with --exclude macos/10-nix-darwin.sh if needed.
EOF
}

nix_binary() {
  if command_exists nix; then
    command -v nix
    return 0
  fi
  if [[ -x "$NIX_DEFAULT_PROFILE" ]]; then
    printf '%s\n' "$NIX_DEFAULT_PROFILE"
    return 0
  fi
  if [[ -x "$NIX_USER_PROFILE" ]]; then
    printf '%s\n' "$NIX_USER_PROFILE"
    return 0
  fi
  return 1
}

nix_available() {
  nix_binary >/dev/null 2>&1
}

run_nix() {
  local nix_bin
  nix_bin="$(nix_binary)" || die "required command not found: nix"
  "$nix_bin" "${NIX_EXPERIMENTAL_FEATURES[@]}" "$@"
}

run_nix_as_root() {
  local nix_bin
  nix_bin="$(nix_binary)" || die "required command not found: nix"
  sudo "$nix_bin" "${NIX_EXPERIMENTAL_FEATURES[@]}" "$@"
}

darwin_hostname() {
  local host="${NIX_DARWIN_HOSTNAME:-}"

  if [[ -z "$host" ]] && command_exists scutil; then
    host="$(scutil --get LocalHostName 2>/dev/null || true)"
  fi
  if [[ -z "$host" ]]; then
    host="$(hostname -s 2>/dev/null || true)"
  fi

  [[ "$host" =~ ^[A-Za-z0-9._-]+$ ]] || die "could not determine a valid macOS hostname"
  printf '%s\n' "$host"
}

darwin_host_platform() {
  case "$(uname -m)" in
    arm64|aarch64) printf '%s\n' "aarch64-darwin" ;;
    x86_64|amd64) printf '%s\n' "x86_64-darwin" ;;
    *) die "unsupported macOS architecture: $(uname -m)" ;;
  esac
}

flake_file() {
  printf '%s\n' "$NIX_DARWIN_CONFIG_DIR/flake.nix"
}

flake_configuration() {
  local platform="$1"

  if [[ "$NIX_DARWIN_CONFIG_DIR" == "$REPO_DIR/nix" ]]; then
    printf '%s\n' "$platform"
  elif [[ -n "$NIX_DARWIN_HOSTNAME" ]]; then
    printf '%s\n' "$NIX_DARWIN_HOSTNAME"
  else
    darwin_hostname
  fi
}

refuse_implicit_legacy_flake() {
  local legacy_flake="$HOME/nix-darwin-config/flake.nix"

  [[ "$NIX_DARWIN_CONFIG_DIR_EXPLICIT" == 1 ]] && return 0
  [[ -f "$legacy_flake" ]] || return 0

  die "existing nix-darwin flake found at $legacy_flake; set NIX_DARWIN_CONFIG_DIR explicitly to select that flake or $REPO_DIR/nix"
}

nix_darwin_etc_files() {
  printf '%s\n' \
    "$NIX_DARWIN_ETC_DIR/nix/nix.conf" \
    "$NIX_DARWIN_ETC_DIR/bashrc" \
    "$NIX_DARWIN_ETC_DIR/zshrc"
}

backup_unmanaged_etc_files() {
  local path backup suffix

  while IFS= read -r path; do
    [[ -e "$path" ]] || continue
    # nix-darwin-managed files are normally symlinks into /nix/store. Leave
    # those alone on later idempotent runs.
    [[ -L "$path" ]] && continue

    backup="${path}.before-nix-darwin"
    suffix=1
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="${path}.before-nix-darwin.${suffix}"
      suffix=$((suffix + 1))
    done

    log "Backing up unmanaged $path to $backup..."
    sudo mv "$path" "$backup"
  done < <(nix_darwin_etc_files)
}

run() {
  local flake flake_ref configuration platform repo_dir

  if [[ -d "$NIX_DARWIN_CONFIG_DIR" ]]; then
    NIX_DARWIN_CONFIG_DIR="$(cd "$NIX_DARWIN_CONFIG_DIR" && pwd -P)"
  fi
  repo_dir="$(cd "$REPO_DIR" && pwd -P)"

  refuse_implicit_legacy_flake
  flake="$(flake_file)"
  [[ -f "$flake" ]] || die "nix-darwin flake not found: $flake"

  platform="$(darwin_host_platform)"
  if [[ "$NIX_DARWIN_CONFIG_DIR" == "$REPO_DIR/nix" && "$platform" != "aarch64-darwin" ]]; then
    die "the repository flake currently supports aarch64-darwin; set NIX_DARWIN_CONFIG_DIR to an external flake for $platform"
  fi

  configuration="$(flake_configuration "$platform")"
  [[ "$configuration" =~ ^[A-Za-z0-9._-]+$ ]] \
    || die "invalid nix-darwin configuration name: $configuration"
  if [[ "$NIX_DARWIN_CONFIG_DIR" == "$repo_dir/nix" ]]; then
    flake_ref="git+file://$repo_dir?dir=nix"
  else
    flake_ref="path:$NIX_DARWIN_CONFIG_DIR"
  fi
  log "Using nix-darwin configuration $configuration ($platform) from $NIX_DARWIN_CONFIG_DIR."

  backup_unmanaged_etc_files

  log "Activating nix-darwin configuration..."
  run_nix_as_root run "git+file://$repo_dir?dir=nix#darwin-rebuild" -- switch \
    --flake "$flake_ref#$configuration" --no-write-lock-file
  log "nix-darwin activated. Reapply with darwin-rebuild switch --flake $flake_ref#$configuration."
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