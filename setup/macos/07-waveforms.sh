#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"
# shellcheck source=common.bash
source "$SCRIPT_DIR/common.bash"

WAVEFORMS_VERSION="3.25.1"
WAVEFORMS_URL="https://files.digilent.com/Software/Waveforms/${WAVEFORMS_VERSION}/digilent.waveforms_v${WAVEFORMS_VERSION}.dmg"
WAVEFORMS_NEWER_URL="https://cloud.digilent.com/myproducts/waveforms?pc=1&tab=2"
WAVEFORMS_DMG_NAME="digilent.waveforms_v${WAVEFORMS_VERSION}.dmg"
APP_PATH="/Applications/WaveForms.app"

# Browser-like headers. files.digilent.com sits behind Cloudflare, which serves
# a JS "managed challenge" to non-browser clients (curl gets HTTP 403 even though
# the same URL downloads fine in Chrome/Firefox/Safari). These headers let curl
# through when Cloudflare is not challenging; otherwise we fall back to the
# default browser (see download_via_browser).
CURL_BROWSER_HEADERS=(
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,application/octet-stream;q=0.9,*/*;q=0.8'
  -H 'Accept-Language: en-US,en;q=0.5'
  -H 'Accept-Encoding: gzip, deflate, br'
  -H 'Upgrade-Insecure-Requests: 1'
  -H 'Sec-Fetch-Dest: document'
  -H 'Sec-Fetch-Mode: navigate'
  -H 'Sec-Fetch-Site: none'
  -H 'Sec-Fetch-User: ?1'
)

presteps() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this step requires macOS"
  require_command curl
  require_command hdiutil
  require_command open
}

help() {
  cat <<'EOF'
Download and install Digilent WaveForms from the official .dmg release. Not
installed via the Brewfile because the cask is not kept up to date on Homebrew.
Idempotent: skips when WaveForms.app is already in /Applications.

files.digilent.com is behind Cloudflare, which blocks plain curl with HTTP 403
(a JS challenge). The script first tries curl with browser-like headers; if that
is challenged it opens the URL in the default browser (where it downloads fine)
and then installs the .dmg once it lands in ~/Downloads.
EOF
}

# Returns 0 if $1 looks like a real Apple disk image rather than a Cloudflare
# challenge / error HTML page served with HTTP 200.
is_real_dmg() {
  local file="$1"
  [[ -s "$file" ]] || return 1
  # Cloudflare challenge pages are HTML starting with "<!DOCTYPE html>".
  head -c 64 "$file" | grep -qi '<!DOCTYPE html\|<html\|Just a moment' && return 1
  # `file` reports "Apple Disk Image" for uncompressed/UDIF images; compressed
  # UDIF images may report "zlib compressed data" or "data" — accept any of
  # those but reject plain text/HTML.
  local kind
  kind="$(file -b "$file" 2>/dev/null || true)"
  case "$kind" in
    *Apple\ Disk\ Image*|*zlib\ compressed\ data*|*data*) return 0 ;;
    *HTML*|*ASCII*|*UTF-8*|*text*) return 1 ;;
    *) return 0 ;;
  esac
}

# Try curl with browser-like headers. Sets WAVEFORMS_DMG_PATH to the
# downloaded dmg path and returns 0 on success, or returns non-zero on
# failure / Cloudflare challenge.
download_via_curl() {
  local out="$1"
  log "Trying curl with browser headers..."
  if curl -fsSL "${CURL_BROWSER_HEADERS[@]}" -o "$out" "$WAVEFORMS_URL" \
       && is_real_dmg "$out"; then
    WAVEFORMS_DMG_PATH="$out"
    return 0
  fi
  rm -f "$out"
  return 1
}

# Cloudflare blocks curl, so hand the URL to the default browser (where it
# downloads fine) and wait for the .dmg to land in ~/Downloads. Sets
# WAVEFORMS_DMG_PATH to the downloaded dmg path on success.
download_via_browser() {
  local downloads_dir="${HOME}/Downloads"
  local expected="${downloads_dir}/${WAVEFORMS_DMG_NAME}"

  # If a previous browser download is already there, reuse it.
  if [[ -f "$expected" ]] && is_real_dmg "$expected"; then
    log "Found existing download: $expected"
    WAVEFORMS_DMG_PATH="$expected"
    return 0
  fi
  # A stale/bad file (e.g. a Cloudflare HTML page saved earlier) would make the
  # wait loop below never see a real dmg — remove it so the browser can replace it.
  if [[ -f "$expected" ]]; then
    log "Removing stale/invalid file at $expected"
    rm -f "$expected"
  fi

  log "Cloudflare blocked the curl download (HTTP 403 / JS challenge)."
  log "Opening the URL in your default browser — please save the .dmg:"
  log "  ${WAVEFORMS_URL}"
  open "$WAVEFORMS_URL"

  log "Waiting for ${WAVEFORMS_DMG_NAME} to appear in ${downloads_dir}..."
  local waited=0
  local prev_size=-1 stable=0
  while (( waited < 600 )); do
    sleep 5
    waited=$((waited + 5))

    # Browsers download to a partial file (e.g. *.dmg.download / *.crdownload)
    # first; only consider the final name once it exists.
    if [[ ! -f "$expected" ]]; then
      continue
    fi

    local size
    size="$(stat -f%z "$expected" 2>/dev/null || echo 0)"
    if [[ "$size" -eq 0 ]]; then
      continue
    fi
    if [[ "$size" -eq "$prev_size" ]]; then
      stable=$((stable + 1))
    else
      stable=0
      prev_size="$size"
    fi

    # Treat the download as complete once the size stops changing for ~10s and
    # the file is a real disk image.
    if (( stable >= 2 )) && is_real_dmg "$expected"; then
      log "Download complete: $expected"
      WAVEFORMS_DMG_PATH="$expected"
      return 0
    fi
  done

  die "timed out waiting for ${WAVEFORMS_DMG_NAME} in ${downloads_dir}"
}

install_dmg() {
  local dmg="$1"
  local mount_point
  mount_point="$(mktemp -d -t waveforms.XXXXXX)"

  log "Mounting $dmg..."
  hdiutil attach -nobrowse -readonly -mountpoint "$mount_point" "$dmg" >/dev/null

  local app_src
  app_src="$(find "$mount_point" -maxdepth 1 -name 'WaveForms.app' -print -quit)"
  [[ -n "$app_src" ]] || { hdiutil detach "$mount_point" >/dev/null; die "WaveForms.app not found in mounted dmg"; }

  log "Installing $app_src -> /Applications"
  cp -R "$app_src" /Applications/

  hdiutil detach "$mount_point" >/dev/null
}

run() {
  log ""
  log "=== Digilent WaveForms ==="

  if [[ -d "$APP_PATH" ]]; then
    log "WaveForms already installed at $APP_PATH"
    log "Newer versions or other platforms (login required): $WAVEFORMS_NEWER_URL"
    return 0
  fi

  local dmg=""
  local tmp_dmg
  tmp_dmg="$(mktemp -t waveforms.XXXXXX).dmg"

  WAVEFORMS_DMG_PATH=""
  if download_via_curl "$tmp_dmg"; then
    :
  else
    log "curl download failed or was blocked by Cloudflare."
    download_via_browser || die "no WaveForms .dmg available to install"
  fi

  dmg="$WAVEFORMS_DMG_PATH"
  [[ -n "$dmg" && -f "$dmg" ]] || die "no WaveForms .dmg available to install"
  is_real_dmg "$dmg" || die "downloaded file is not a valid .dmg: $dmg"

  install_dmg "$dmg"

  # Only clean up the temp curl download; keep the browser-downloaded file in
  # ~/Downloads so the user can re-run/reinstall without re-downloading.
  case "$dmg" in
    "$tmp_dmg") rm -f "$dmg" ;;
  esac

  log "WaveForms installed at $APP_PATH"
  log "Newer versions or other platforms (login required): $WAVEFORMS_NEWER_URL"
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
