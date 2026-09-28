#!/usr/bin/env bash
set -euo pipefail

# Configures git clean/smudge filters for this dotfiles repo.
# Run once after cloning: ./setup.git-filters.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PKCS#11 provider path filter for SSH config.
# clean:  tokenizes real provider paths → @YKCS11@/@OPENSC@ (portable commits)
# smudge: resolves tokens → current platform's real paths (live working tree)
git config filter.pkcs11-provider.clean "$REPO_DIR/ssh/pkcs11-filter.sh clean"
git config filter.pkcs11-provider.smudge "$REPO_DIR/ssh/pkcs11-filter.sh smudge"
git config filter.pkcs11-provider.required true

# API key scrub filter for junie model configs.
git config filter.scrub-apikey.clean \
  "sed -E 's/(\"apiKey\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/\\1\"REDACTED\"/'"
git config filter.scrub-apikey.smudge cat
git config filter.scrub-apikey.required true

echo "Git filters configured:"
echo "  pkcs11-provider (clean+smudge) → ssh/config.d/*"
echo "  scrub-apikey    (clean)        → junie/models/*.json"
