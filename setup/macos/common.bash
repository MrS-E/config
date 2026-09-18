#!/usr/bin/env bash
# macOS-specific helper library for setup steps.
#
# Sourced by macOS step scripts via:
#   source "$SCRIPT_DIR/common.bash"
# This file is NOT executable — the runner does not discover it as a step.
#
# Contains Homebrew, keychain, and macOS-specific installer/downloader guards.
# Platform-neutral primitives live in setup/general/common.bash.

[[ -n "${_SETUP_MACOS_COMMON:-}" ]] && return 0
_SETUP_MACOS_COMMON=1

# Source general helpers if not already sourced.
if [[ -z "${_SETUP_GENERAL_COMMON:-}" ]]; then
  # shellcheck source=../general/common.bash
  source "$REPO_DIR/setup/general/common.bash"
fi

# Ensure Homebrew is installed and on PATH. Idempotent.
ensure_homebrew() {
  if command_exists brew; then
    log "Homebrew already installed."
    return 0
  fi

  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command_exists brew || die "Homebrew installation finished but brew is still not on PATH"
}

# Ensure ssh-agent is running for the current user. Idempotent.
ensure_ssh_agent() {
  if pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    log "ssh-agent already running."
    return 0
  fi
  log "Starting ssh-agent..."
  eval "$(ssh-agent -s)" >/dev/null
}