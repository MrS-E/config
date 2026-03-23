#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.ssh"

ln -sfn "$DIR/zshrc" "$HOME/.zshrc"
ln -sfn "$DIR/vimrc" "$HOME/.vimrc"
ln -sfn "$DIR/vim" "$HOME/.vim"
ln -sfn "$DIR/gitconfig" "$HOME/.gitconfig"
ln -sfn "$DIR/nvim" "$HOME/.config/nvim"
ln -sfn "$DIR/lazygit" "$HOME/.config/lazygit"
ln -sfn "$DIR/ghostty" "$HOME/.config/ghostty"
ln -sfn "$DIR/Nextcloud" "$HOME/.config/Nextcloud"

# ln -sfn "$DIR/ssh" "$HOME/.ssh"
ln -sfn "$DIR/ssh/config" "$HOME/.ssh/config"

