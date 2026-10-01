#!/usr/bin/env bash
# macOS-specific helper library for setup steps.
#
# Sourced by macOS step scripts via:
#   source "$SCRIPT_DIR/common.bash"
# This file is NOT executable — the runner does not discover it as a step.
#
# Contains keychain and macOS-specific installer/downloader guards.
# Platform-neutral primitives live in setup/general/common.bash.

[[ -n "${_SETUP_MACOS_COMMON:-}" ]] && return 0
_SETUP_MACOS_COMMON=1

# Source general helpers if not already sourced.
if [[ -z "${_SETUP_GENERAL_COMMON:-}" ]]; then
  # shellcheck source=../general/common.bash
  source "$REPO_DIR/setup/general/common.bash"
fi

# Ensure ssh-agent is running for the current user. Idempotent.
ensure_ssh_agent() {
  if pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
    log "ssh-agent already running."
    return 0
  fi
  log "Starting ssh-agent..."
  eval "$(ssh-agent -s)" >/dev/null
}