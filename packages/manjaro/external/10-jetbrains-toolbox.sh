#!/usr/bin/env bash
set -euo pipefail

version="3.0.1.59888"
base_dir="$HOME/.config/jetbrains"
archive="$base_dir/jetbrains-toolbox-$version.tar.gz"
unpacked="$base_dir/jetbrains-toolbox-$version"
bin="$unpacked/bin/jetbrains-toolbox"

mkdir -p "$base_dir"

if [[ ! -x "$bin" ]]; then
  echo "Installing JetBrains Toolbox..."
  wget -O "$archive" "https://download.jetbrains.com/toolbox/jetbrains-toolbox-$version.tar.gz"
  tar -xzf "$archive" -C "$base_dir"
fi

nohup "$bin" >/dev/null 2>&1 &