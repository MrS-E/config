#!/usr/bin/env bash
set -euo pipefail

if ! command -v joplin >/dev/null 2>&1; then
  echo "Installing Joplin..."
  wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
fi