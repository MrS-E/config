#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../general/common.bash
source "$REPO_DIR/setup/general/common.bash"

OPENSSH_VERSION="10.1p1"
OPENSSH_MIN_VERSION="10.1"
OPENSSH_TARBALL="openssh-$OPENSSH_VERSION.tar.gz"
OPENSSH_URL="https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/$OPENSSH_TARBALL"
OPENSSH_SHA256="b9fc7a2b82579467a6f2f43e4a81c8e1dfda614ddb4f9b255aafd7020bbf0758"
OPENSSH_PREFIX="$HOME/.local"
OPENSSH_BIN="$OPENSSH_PREFIX/bin/ssh"
SSH_KEYGEN_BIN="$OPENSSH_PREFIX/bin/ssh-keygen"
OPENSSH_CONFIG="$OPENSSH_PREFIX/etc/ssh_config"
YUBIKEY_PROVIDER="/usr/lib64/libykcs11.so.2"
YUBIKEY_RSA_PUBLIC_KEY="$HOME/.ssh/yubikey-9a.pub"
YUBIKEY_ED25519_PUBLIC_KEY="$HOME/.ssh/yubikey-9d.pub"
CLIENT_BINARIES=(ssh scp ssh-add ssh-agent ssh-keygen ssh-keyscan sftp)
BUILD_DIR=""

cleanup() {
  if [[ -n "$BUILD_DIR" ]]; then
    rm -rf -- "$BUILD_DIR"
  fi
}

trap cleanup EXIT

presteps() {
  [[ -f /etc/fedora-release ]] || die "this step requires Fedora"
  require_command curl
  require_command gcc
  require_command make
  require_command sha256sum
  require_command tar
  require_command sort
  require_command install
  require_command openssl
  require_command python3
  require_command yubico-piv-tool
  [[ -r /usr/include/openssl/ssl.h ]] || die "OpenSSL headers are required"
  [[ -r /usr/include/zlib.h ]] || die "zlib headers are required"
  [[ -r "$YUBIKEY_PROVIDER" ]] || die "YubiKey PKCS#11 provider not found: $YUBIKEY_PROVIDER"
}

help() {
  cat <<'EOF'
Build OpenSSH 10.1p1 in ~/.local for Ed25519 keys hosted by a PKCS#11 token.
The system OpenSSH 10.0p1 client cannot read the Ed25519 key in YubiKey PIV slot 9d.
Idempotent: skips an existing compatible ~/.local/bin/ssh and exports the 9a/9d public keys when the YubiKey is connected.
EOF
}

ssh_version() {
  "$1" -V 2>&1 | sed -n 's/^OpenSSH_\([0-9][0-9.]*\)p[0-9][0-9]*/\1/p'
}

supports_ed25519_pkcs11() {
  local version
  version="$(ssh_version "$1")"
  [[ -n "$version" ]] && [[ "$(printf '%s\n%s\n' "$OPENSSH_MIN_VERSION" "$version" | sort -V | head -1)" == "$OPENSSH_MIN_VERSION" ]]
}

client_tools_ready() {
  local binary
  for binary in "${CLIENT_BINARIES[@]}"; do
    [[ -x "$OPENSSH_PREFIX/bin/$binary" ]] || return 1
  done
  [[ -x "$OPENSSH_PREFIX/libexec/ssh-pkcs11-helper" ]] && supports_ed25519_pkcs11 "$OPENSSH_BIN"
}

install_client_tools() {
  local binary
  ensure_dir "$OPENSSH_PREFIX/bin"
  ensure_dir "$OPENSSH_PREFIX/libexec"
  ensure_dir "$OPENSSH_PREFIX/etc"
  for binary in "${CLIENT_BINARIES[@]}"; do
    install -m 0755 "$binary" "$OPENSSH_PREFIX/bin/$binary"
  done
  install -m 0755 ssh-pkcs11-helper "$OPENSSH_PREFIX/libexec/ssh-pkcs11-helper"
  [[ -e "$OPENSSH_CONFIG" ]] || install -m 0644 ssh_config "$OPENSSH_CONFIG"
}

export_certificate_public_key() {
  local slot output algorithm cert pem der key_file key
  slot="$1"
  output="$2"
  algorithm="$3"
  cert="$(mktemp)"
  pem="$(mktemp)"
  der="$(mktemp)"
  trap 'rm -f "${cert:-}" "${pem:-}" "${der:-}" "${key_file:-}"' RETURN

  if ! yubico-piv-tool -a read-certificate -s "$slot" > "$cert" 2>/dev/null; then
    log "YubiKey unavailable; insert it and rerun this step to export $output."
    return 0
  fi
  openssl x509 -in "$cert" -pubkey -noout > "$pem"
  openssl pkey -pubin -in "$pem" -outform DER -out "$der"

  if [[ "$algorithm" == rsa ]]; then
    key="$($SSH_KEYGEN_BIN -i -m PKCS8 -f "$pem")"
  else
    key="$(python3 -c 'import base64,struct,sys; d=open(sys.argv[1], "rb").read(); p=bytes.fromhex("302a300506032b6570032100"); assert d.startswith(p) and len(d) == len(p) + 32, "unexpected Ed25519 SubjectPublicKeyInfo"; k=struct.pack(">I", 11) + b"ssh-ed25519" + struct.pack(">I", 32) + d[-32:]; print("ssh-ed25519 " + base64.b64encode(k).decode())' "$der")"
  fi

  ensure_dir "$(dirname "$output")"
  key_file="$(mktemp "${output}.tmp.XXXXXX")"
  chmod 600 "$key_file"
  printf '%s\n' "$key" > "$key_file"
  mv -f "$key_file" "$output"
  log "Exported YubiKey PIV slot $slot public key to $output."
}

export_yubikey_public_keys() {
  export_certificate_public_key 9a "$YUBIKEY_RSA_PUBLIC_KEY" rsa
  export_certificate_public_key 9d "$YUBIKEY_ED25519_PUBLIC_KEY" ed25519
}

run() {
  if client_tools_ready; then
    log "OpenSSH with Ed25519 PKCS#11 support already installed ($($OPENSSH_BIN -V 2>&1))."
    export_yubikey_public_keys
    return 0
  fi

  BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/openssh-$OPENSSH_VERSION.XXXXXX")"
  log "Downloading OpenSSH $OPENSSH_VERSION..."
  curl --proto '=https' --tlsv1.2 --fail --location --retry 3 --output "$BUILD_DIR/$OPENSSH_TARBALL" "$OPENSSH_URL"
  printf '%s  %s\n' "$OPENSSH_SHA256" "$BUILD_DIR/$OPENSSH_TARBALL" | sha256sum --check --status || die "OpenSSH checksum verification failed"

  tar -C "$BUILD_DIR" -xzf "$BUILD_DIR/$OPENSSH_TARBALL"
  (
    cd "$BUILD_DIR/openssh-$OPENSSH_VERSION"
    ./configure --prefix="$OPENSSH_PREFIX" --sysconfdir="$OPENSSH_PREFIX/etc" --without-kerberos5 --without-pam
    make -j"$(getconf _NPROCESSORS_ONLN)"
    install_client_tools
  )

  supports_ed25519_pkcs11 "$OPENSSH_BIN" || die "installed OpenSSH does not support Ed25519 PKCS#11 keys"
  log "Installed $($OPENSSH_BIN -V 2>&1) at $OPENSSH_BIN."
  export_yubikey_public_keys
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