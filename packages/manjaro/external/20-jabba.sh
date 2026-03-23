#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "$HOME/.jabba" ]]; then
  echo "Installing jabba..."
  curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
fi