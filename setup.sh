#!/bin/bash

set -e

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$CONFIG_DIR/Brewfile"
SSH_DIR="$CONFIG_DIR/ssh"
NVIM_DIR="$CONFIG_DIR/nvim"
GHOSTTY_DIR="$CONFIG_DIR/ghostty"
VIM_DIR="$CONFIG_DIR/vim"

echo "Starting setup..."

# 1. Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

# Add Homebrew to PATH if it's not in PATH (for new installations)
if ! command -v brew &> /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)" # for Apple Silicon
  eval "$(/usr/local/bin/brew shellenv)"    # for Intel
fi

# 2. Symlink config files
FILES=(zshrc vimrc gitconfig)
for file in "${FILES[@]}"; do
  SRC="$CONFIG_DIR/$file"
  DEST="$HOME/.$file"
  if [ -L "$DEST" ] || [ -f "$DEST" ]; then
    echo "Removing existing file or link: $DEST"
    rm -f "$DEST"
  fi
  echo "Creating symlink for $file"
  ln -s "$SRC" "$DEST"
done

#3. Symlink nvim config
ln -sfn "$NVIM_DIR" "$HOME/.config/nvim"

#4. Ghostty config
ln -sfn "$GHOSTTY_DIR" "$HOME/.config/ghostty"

ln -sfn "$VIM_DIR" "$HOME/.vim"

# 3. Symlink SSH directory
if [ -d "$SSH_DIR" ]; then
  if [ -L "$HOME/.ssh" ] || [ -d "$HOME/.ssh" ]; then
    echo "Removing existing ~/.ssh directory or symlink"
    rm -rf "$HOME/.ssh"
  fi
  echo "Creating symlink for ssh directory"
  ln -s "$SSH_DIR" "$HOME/.ssh"
fi

# 4. Ensure ssh-agent is running (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
  if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
  fi
fi

# 5. Add SSH keys to Apple Keychain (macOS only)
if [[ "$(uname)" == "Darwin" ]] && [ -d "$HOME/.ssh" ]; then
  SSH_KEYS=$(find "$HOME/.ssh" -type f -not -name "*.pub" -perm 600 2>/dev/null)

  if [ -n "$SSH_KEYS" ]; then
    for key in $SSH_KEYS; do
      if ! ssh-add -l 2>/dev/null | grep -q "$key"; then
        echo "Adding SSH key $key to Apple keychain..."
        ssh-add --apple-use-keychain "$key"
      else
        echo "SSH key $key is already loaded in ssh-agent."
      fi
    done
  else
    echo "No private SSH keys found in ~/.ssh."
  fi
fi

# 5. Install vim theme
mkdir -p ~/.vim/pack/themes/start
cd ~/.vim/pack/themes/start
if [ ! -d "dracula" ]; then
  echo "Installing dracular for vim"
  git clone https://github.com/dracula/vim.git dracula
fi
cd -

# 6. Install Homebrew packages from Brewfile
if [ -f "$BREWFILE" ]; then
  echo "Installing Homebrew packages from Brewfile..."
  brew bundle --file="$BREWFILE"
else
  echo "No Brewfile found at $BREWFILE"
  echo "To create one use brew bundle dump --describe --file=~/Brewfile --force"
fi

echo "✅ Setup complete."
