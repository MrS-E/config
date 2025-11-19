#!/bin/bash
# ---- project.sh: tiny project switcher -------------------------------------------------
# Usage:
#   source /path/to/project.sh
#   project -a myproj ~/src/myproj
#   project -d myproj "Cool service"
#   project myproj        # cd's there
#   project -i myproj     # show info
#   project -l            # list grouped by path

# Config (override these in shell before sourcing)
: "${PROJECT_DB_DIR:="$HOME/.local/share/projectctl"}"

# Internal helpers
_project__dbdir() {
  local d="${PROJECT_DB_DIR:-$HOME/.local/share/projectctl}"
  if command -v mkdir >/dev/null 2>&1; then
    mkdir -p "$d" 2>/dev/null || true
  elif [[ -x /bin/mkdir ]]; then
    /bin/mkdir -p "$d" 2>/dev/null || true
  elif [[ -x /usr/bin/mkdir ]]; then
    /usr/bin/mkdir -p "$d" 2>/dev/null || true
  else
    printf '\033[33mWarning:\033[0m cannot find mkdir; please create %s manually\n' "$d" >&2
  fi
  printf '%s\n' "$d"
}

_project__file() {
  local n="$1"
  n="${n//[^A-Za-z0-9._-]/_}"
  printf '%s/%s.proj' "$(_project__dbdir)" "$n"
}

_project__save() {
  local name="$1" path="$2" desc="$3" file
  file="$(_project__file "$name")"
  if command -v realpath >/dev/null 2>&1; then
    path="$(realpath -m -- "$path" 2>/dev/null || printf '%s' "$path")"
  fi
  {
    printf 'name=%q\n' "$name"
    printf 'path=%q\n' "$path"
    printf 'desc=%q\n' "$desc"
  } >"$file"
}

# Load a record: outputs path and desc to stdout as two lines (empty desc ok)
_project__load() {
  local name="$1" file; file="$(_project__file "$name")"
  [[ -f "$file" ]] || return 1
  # shellcheck disable=SC1090
  set -o noglob 2>/dev/null || true
  local path desc
  . "$file" 2>/dev/null || return 1
  printf '%s\n%s\n' "$path" "$desc"
}

_project__exists() {
  [[ -f "$(_project__file "$1")" ]]
}

_project__error() { printf '\033[31m❌ %s\033[0m\n' "$*" 1>&2; }
_project__info()  { printf '\033[36m➜ %s\033[0m\n' "$*"; }
_project__ok()    { printf '\033[32m✔ %s\033[0m\n' "$*"; }

project() {
  # needed because path could not be build completly at zshrc source time
  local PATH="$PATH:/usr/bin:/bin:/usr/local/bin"

  _project__dbdir >/dev/null

  # Help
      if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    printf '%s\n' \
'project - tiny project switcher

Commands:
  project NAME           cd to registered path
  project -a NAME PATH   add/update mapping
  project -d NAME "desc" set/replace description
  project -i NAME        show path + description
  project -l             list projects grouped by path
  project -h             help

Notes:
  • Data: $PROJECT_DB_DIR (default: ~/.local/share/projectctl).
  • Source this file, do not execute it.'
    return 0
  fi

  # Option switches
  case "$1" in
    -a)
      local name="$2" path="$3"
      if [[ -z "$name" || -z "$path" ]]; then
        _project__error "Usage: project -a NAME PATH"
        return 2
      fi
      if [[ ! -d "$path" ]]; then
        _project__error "Path does not exist: $path"
        return 2
      fi
      _project__save "$name" "$path" ""
      _project__ok "Saved '$name' → $path"
      return 0
      ;;
    -d)
      local name="$2"; shift 2 || true
      local desc="$*"
      if [[ -z "$name" ]]; then
        _project__error "Usage: project -d NAME \"description\""
        return 2
      fi
      if ! _project__exists "$name"; then
        _project__error "No such project: $name"
        return 1
      fi
      # keep existing path
      local path curdesc
      read -r path curdesc < <(_project__load "$name") || return 1
      _project__save "$name" "$path" "$desc"
      _project__ok "Description set for '$name'"
      return 0
      ;;
    -i)
      local name="$2"
      if [[ -z "$name" ]]; then
        _project__error "Usage: project -i NAME"
        return 2
      fi
      if ! _project__exists "$name"; then
        _project__error "No such project: $name"
        return 1
      fi
      local path desc
      read -r path desc < <(_project__load "$name") || return 1
      printf '\033[1m%s\033[0m\n' "$name"
      printf '  Path: %s\n' "$path"
      [[ -n "$desc" ]] && printf '  Desc: %s\n' "$desc"
      return 0
      ;;
    -l)
      # List all projects grouped by path, condensed format
      local f path name desc
      local tmp="${TMPDIR:-/tmp}/project.$$.tmp"
      : >"$tmp" || { _project__error "Cannot create temp file"; return 1; }

      # Gather info
      if [[ -n "$ZSH_VERSION" ]]; then
        setopt local_options null_glob
        for f in "$(_project__dbdir)"/*.proj(N); do
          [[ -e "$f" ]] || continue
          . "$f" 2>/dev/null || continue
          printf '%s\t%s\t%s\n' "$path" "$name" "${desc:-}" >>"$tmp"
        done
      else
        shopt -s nullglob
        for f in "$(_project__dbdir)"/*.proj; do
          [[ -e "$f" ]] || continue
          . "$f" 2>/dev/null || continue
          printf '%s\t%s\t%s\n' "$path" "$name" "${desc:-}" >>"$tmp"
        done
        shopt -u nullglob
      fi

      if [[ ! -s "$tmp" ]]; then
        _project__info "No projects saved yet. Use: project -a NAME PATH"
        rm -f "$tmp"
        return 0
      fi

      # Sort by path
      if command -v sort >/dev/null 2>&1; then
        local tmp_sorted="${TMPDIR:-/tmp}/project.$$.sorted"
        sort -t$'\t' -k1,1 "$tmp" >"$tmp_sorted" && mv "$tmp_sorted" "$tmp"
      fi

      # Group by path
      local current_path="" names descs
      while IFS=$'\t' read -r path name desc; do
        if [[ "$path" != "$current_path" && -n "$current_path" ]]; then
          # print previous group before switching
          printf '\033[1m%s\033[0m\n' "${names%, }"
          [[ -n "$descs" ]] && printf '%s\n' "$descs"
          printf '%s\n\n' "$current_path"
          names=""; descs=""
        fi
        current_path="$path"
        names+="$name, "
        [[ -n "$desc" ]] && descs="${descs:+$descs, }$desc"
      done <"$tmp"

      # Print last group
      if [[ -n "$current_path" ]]; then
        printf '\033[1m%s\033[0m\n' "${names%, }"
        [[ -n "$descs" ]] && printf '%s\n' "$descs"
        printf '%s\n' "$current_path"
      fi
      printf '\n'

      rm -f "$tmp"
      return 0
      ;;

    *)
      # project NAME → cd into it
      local name="$1" path desc
      if ! _project__exists "$name"; then
        _project__error "No such project: $name"
        return 1
      fi
      read -r path desc < <(_project__load "$name") || return 1
      if [[ ! -d "$path" ]]; then
        _project__error "Path no longer exists: $path"
        return 1
      fi
      builtin cd "$path" || return 1
      [[ -n "$desc" ]] && _project__info "$name — $desc"
      return 0
      ;;
  esac
}

# ------------------ Zsh completions ("shell hints") ------------------
# If running under zsh, install a simple completion for `project`
if [ -n "${ZSH_VERSION-}" ]; then
  _project_complete() {
    local -a opts projs
    opts=(-a -d -i -l -h --help)
    projs=("${(@f)$(/bin/ls -1 "$PROJECT_DB_DIR" 2>/dev/null | sed 's/\.proj$//')}")
    # If first word is an option expecting name, complete names; else complete options/names.
    case "${words[2]:-}" in
      -i|-d) _describe -t projects 'project names' projs && return ;;
    esac
    _arguments \
      '(-a -d -i -l -h)--help[Show help]' \
      '(-a -d -i -l -h)-h[Show help]' \
      '(-a -d -i -l -h)-l[List projects]' \
      '(-d -i -l -h)-a[Add project]:name: :path:_files -/' \
      '(-a -i -l -h)-d[Set description]:name: :desc:' \
      '(-a -d -l -h)-i[Info]:name:' \
      '*:project name:->pname' && return
    if [[ $state == pname ]]; then
      _describe -t projects 'project names' projs
    fi
  }
  compdef _project_complete project
fi
# ----------------------------------------------------------------------------------------

