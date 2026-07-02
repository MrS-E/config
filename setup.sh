#!/usr/bin/env bash
set -euo pipefail

# Root setup runner — orchestration only.
# Detects the OS, discovers numbered step scripts under setup/general/ and the
# detected setup/<os>/ directory, applies selection filters, and runs each
# selected step as a separate process via `presteps` then `run`.
# No setup logic lives in this file.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$REPO_DIR/setup"

log() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: setup.sh [MODE] [SELECTORS]

OS setup runner. Discovers numbered step scripts under setup/general/ and the
detected OS directory (setup/<os>/), then runs each selected step's
presteps + run as a separate process.

OS detection:
  Darwin                            -> macos
  Linux + /etc/fedora-release
         + rpm-ostree                -> fedora-atomic
  Linux + /etc/fedora-release         -> fedora
  Linux + /etc/manjaro-release        -> manjaro

Modes:
  (default) | --all        run all discovered steps (general first, then OS)
  --only SEL[,SEL,...]     run exactly the selected discovered steps
  --exclude SEL[,SEL,...]  run all discovered steps except the selected ones
  --interactive            choose steps with fzf --multi (falls back to flags)
  --list                   list discovered steps with help text and exit
  --help                   show this help and exit

Selectors (matched in order: <scope>/<file>, <file>, <basename>):
  general/01-symlinks.sh
  01-symlinks.sh
  01-symlinks

Examples:
  ./setup.sh
  ./setup.sh --all
  ./setup.sh --only general/01-symlinks.sh
  ./setup.sh --only fedora/06-flatpak-apps.sh,fedora/08-zsh-plugins.sh
  ./setup.sh --exclude fedora/14-tailscale.sh
  ./setup.sh --interactive
  ./setup.sh --list
EOF
}

detect_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos' ;;
    Linux)
      if [[ -f /etc/fedora-release ]]; then
        if command -v rpm-ostree >/dev/null 2>&1; then
          printf 'fedora-atomic'
        else
          printf 'fedora'
        fi
      elif [[ -f /etc/manjaro-release ]]; then
        printf 'manjaro'
      else
        return 1
      fi
      ;;
    *) return 1 ;;
  esac
}

# Print executable *.sh step paths (absolute) in a scope dir, sorted lexically.
discover_scope() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local f
  while IFS= read -r f; do
    [[ -x "$f" ]] && printf '%s\n' "$f"
  done < <(find "$dir" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)
}

# Step registry: parallel arrays of scope and absolute path.
declare -a STEP_SCOPE=()
declare -a STEP_PATH=()

add_steps_from() {
  local scope="$1" dir="$2" path
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    STEP_SCOPE+=("$scope")
    STEP_PATH+=("$path")
  done < <(discover_scope "$dir")
}

step_count() { printf '%s\n' "${#STEP_PATH[@]}"; }

# Fully-qualified ID for step index $1: <scope>/<filename>
step_fq() {
  local idx="$1"
  printf '%s/%s\n' "${STEP_SCOPE[$idx]}" "$(basename "${STEP_PATH[$idx]}")"
}

# Return 0 if selector $1 matches step index $2.
step_matches() {
  local selector="$1" idx="$2"
  local scope path fname base fq
  scope="${STEP_SCOPE[$idx]}"
  path="${STEP_PATH[$idx]}"
  fname="$(basename "$path")"
  base="${fname%.sh}"
  fq="$scope/$fname"
  [[ "$selector" == "$fq" || "$selector" == "$fname" || "$selector" == "$base" ]]
}

# Count how many discovered steps a selector matches.
selector_match_count() {
  local selector="$1" idx count=0
  for idx in "${!STEP_PATH[@]}"; do
    if step_matches "$selector" "$idx"; then count=$((count + 1)); fi
  done
  printf '%s\n' "$count"
}

# Validate that every selector in a comma list matches exactly one step.
validate_selectors() {
  local list="$1" IFS=','
  local sel
  for sel in $list; do
    sel="${sel# }"; sel="${sel% }"
    [[ -n "$sel" ]] || continue
    local n
    n="$(selector_match_count "$sel")"
    if [[ "$n" -eq 0 ]]; then
      err "unknown step selector: $sel"
      exit 1
    fi
    if [[ "$n" -gt 1 ]]; then
      err "ambiguous step selector: $sel (matches $n steps)"
      exit 1
    fi
  done
}

# Print "scope/filename<TAB>help" for each discovered step.
list_steps() {
  local idx
  for idx in "${!STEP_PATH[@]}"; do
    local fq="${STEP_SCOPE[$idx]}/$(basename "${STEP_PATH[$idx]}")"
    local help_text
    help_text="$("${STEP_PATH[$idx]}" help 2>/dev/null | head -1 || true)"
    printf '%s\t%s\n' "$fq" "$help_text"
  done
}

# Interactive selection via fzf --multi. Prints selected fully-qualified IDs.
interactive_select() {
  if ! command -v fzf >/dev/null 2>&1; then
    err "interactive mode requires fzf, which was not found."
    err "Use flag-based selection instead, e.g.:  ./setup.sh --only general/01-symlinks.sh"
    exit 1
  fi
  local entries=() idx
  for idx in "${!STEP_PATH[@]}"; do
    local fq="${STEP_SCOPE[$idx]}/$(basename "${STEP_PATH[$idx]}")"
    local help_text
    help_text="$("${STEP_PATH[$idx]}" help 2>/dev/null | head -1 || true)"
    entries+=("$fq — $help_text")
  done
  printf '%s\n' "${entries[@]}" | fzf --multi --prompt="setup steps> " \
    | sed 's/ — .*//'
}

run_step() {
  local scope="$1" path="$2"
  local label="$scope/$(basename "$path")"
  log "==> $label: presteps"
  if ! "$path" presteps; then
    log "    presteps failed; skipping run"
    return 2
  fi
  log "==> $label: run"
  if ! "$path" run; then
    log "    run failed"
    return 1
  fi
  return 0
}

main() {
  local mode="all"
  local selectors=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --list)    mode="list"; shift ;;
      --all)     mode="all"; shift ;;
      --only)    mode="only"; selectors="${2:-}"; shift 2 ;;
      --exclude) mode="exclude"; selectors="${2:-}"; shift 2 ;;
      --interactive) mode="interactive"; shift ;;
      --only=*)       mode="only"; selectors="${1#--only=}"; shift ;;
      --exclude=*)    mode="exclude"; selectors="${1#--exclude=}"; shift ;;
      *) err "unknown argument: $1"; usage >&2; exit 2 ;;
    esac
  done

  local os_id
  if ! os_id="$(detect_os)"; then
    err "unsupported or undetectable OS"
    exit 1
  fi
  log "Detected OS: $os_id"

  add_steps_from "general" "$SETUP_DIR/general"
  add_steps_from "$os_id" "$SETUP_DIR/$os_id"

  if [[ "$(step_count)" -eq 0 ]]; then
    err "no setup steps discovered under setup/general/ or setup/$os_id/"
    exit 1
  fi

  if [[ "$mode" == "list" ]]; then
    list_steps | column -t -s $'\t' 2>/dev/null || list_steps
    exit 0
  fi

  # Build the selected index list.
  local selected=() idx
  case "$mode" in
    all)
      for idx in "${!STEP_PATH[@]}"; do selected+=("$idx"); done
      ;;
    only)
      validate_selectors "$selectors"
      local IFS=','
      local sel
      for sel in $selectors; do
        sel="${sel# }"; sel="${sel% }"
        [[ -n "$sel" ]] || continue
        for idx in "${!STEP_PATH[@]}"; do
          if step_matches "$sel" "$idx"; then selected+=("$idx"); fi
        done
      done
      ;;
    exclude)
      validate_selectors "$selectors"
      local IFS=','
      local sel
      for idx in "${!STEP_PATH[@]}"; do
        local drop=0
        for sel in $selectors; do
          sel="${sel# }"; sel="${sel% }"
          [[ -n "$sel" ]] || continue
          if step_matches "$sel" "$idx"; then drop=1; break; fi
        done
        [[ "$drop" -eq 0 ]] && selected+=("$idx")
      done
      ;;
    interactive)
      local picks pick
      picks="$(interactive_select)" || { err "no steps selected"; exit 1; }
      while IFS= read -r pick; do
        pick="${pick# }"; pick="${pick% }"
        [[ -n "$pick" ]] || continue
        for idx in "${!STEP_PATH[@]}"; do
          if step_matches "$pick" "$idx"; then selected+=("$idx"); fi
        done
      done <<< "$picks"
      ;;
  esac

  if [[ "${#selected[@]}" -eq 0 ]]; then
    err "no steps selected"
    exit 1
  fi

  log "Running ${#selected[@]} step(s) for $os_id."
  local executed=0 failed=0 skipped=0
  for idx in "${selected[@]}"; do
    if run_step "${STEP_SCOPE[$idx]}" "${STEP_PATH[$idx]}"; then
      executed=$((executed + 1))
    else
      local rc=$?
      if [[ "$rc" -eq 2 ]]; then
        skipped=$((skipped + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done

  log ""
  log "Summary: executed=$executed failed=$failed skipped=$skipped"
  [[ "$failed" -eq 0 ]] || exit 1
}

main "$@"