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
NIX_DARWIN_CONFIG_DIR="${NIX_DARWIN_CONFIG_DIR:-$HOME/nix-darwin-config}"
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
Bootstrap an optional nix-darwin configuration in ~/nix-darwin-config. The
generated flake is adapted to the current hostname and macOS architecture, then
configured with Nix flakes, then activated as root. Existing installer-managed
/etc files are preserved with *.before-nix-darwin backups; skip this step with
--exclude macos/10-nix-darwin.sh if needed.
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

rename_simple_configuration() {
  local flake="$1"
  local host="$2"
  local tmp

  grep -qF 'darwinConfigurations."simple"' "$flake" || return 0

  tmp="$(mktemp "${flake}.tmp.XXXXXX")"
  sed "s/darwinConfigurations\.\"simple\"/darwinConfigurations.\"$host\"/g" \
    "$flake" > "$tmp"
  mv "$tmp" "$flake"
}

add_configuration_options() {
  local flake="$1"
  local platform="$2"
  local tmp add_platform=1 add_nix_settings=1

  grep -Eq '^[[:space:]]*nixpkgs\.hostPlatform[[:space:]]*=' "$flake" \
    && add_platform=0
  grep -Eq '^[[:space:]]*nix\.settings\.experimental-features[[:space:]]*=' "$flake" \
    && add_nix_settings=0

  (( add_platform || add_nix_settings )) || return 0

  tmp="$(mktemp "${flake}.tmp.XXXXXX")"
  if ! awk -v platform="$platform" '
    !inserted && /configuration[[:space:]]*=[[:space:]]*[{][^}]*}[[:space:]]*:[[:space:]]*[{]/ {
      print
      if (add_platform) {
        printf "      nixpkgs.hostPlatform = \"%s\";\n", platform
      }
      if (add_nix_settings) {
        printf "      nix.settings.experimental-features = \"nix-command flakes\";\n"
      }
      inserted = 1
      next
    }
    { print }
    END { if (!inserted) exit 1 }
  ' add_platform="$add_platform" add_nix_settings="$add_nix_settings" \
    "$flake" > "$tmp"; then
    rm -f "$tmp"
    die "could not find the generated nix-darwin configuration in $flake"
  fi
  mv "$tmp" "$flake"
}

configure_flake() {
  local flake="$1"
  local host="$2"
  local platform="$3"

  rename_simple_configuration "$flake" "$host"
  add_configuration_options "$flake" "$platform"
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

prepare_flake_lock() {
  local lock="$NIX_DARWIN_CONFIG_DIR/flake.lock"

  if [[ -e "$lock" && ! -w "$lock" ]]; then
    log "Restoring user ownership of $lock..."
    sudo chown "$(id -u):$(id -g)" "$lock"
  fi

  log "Resolving nix-darwin flake inputs as the current user..."
  (
    cd "$NIX_DARWIN_CONFIG_DIR"
    run_nix flake lock
  )
}

run() {
  local flake host platform
  flake="$(flake_file)"

  ensure_dir "$NIX_DARWIN_CONFIG_DIR"
  if [[ -f "$flake" ]]; then
    log "Using existing nix-darwin flake: $flake"
  else
    log "Initializing nix-darwin flake in $NIX_DARWIN_CONFIG_DIR..."
    (
      cd "$NIX_DARWIN_CONFIG_DIR"
      run_nix flake init -t nix-darwin
    )
  fi

  [[ -f "$flake" ]] || die "nix flake init did not create $flake"

  host="$(darwin_hostname)"
  platform="$(darwin_host_platform)"
  configure_flake "$flake" "$host" "$platform"
  log "Configured nix-darwin for $host ($platform)."

  prepare_flake_lock
  backup_unmanaged_etc_files

  log "Activating nix-darwin configuration..."
  (
    cd "$NIX_DARWIN_CONFIG_DIR"
    run_nix_as_root run nix-darwin -- switch --flake . --no-write-lock-file
  )
  log "nix-darwin activated. Use sudo darwin-rebuild switch --flake $NIX_DARWIN_CONFIG_DIR for later changes."
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