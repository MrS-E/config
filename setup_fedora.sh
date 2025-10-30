#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Normal Fedora setup (non-Atomic)
# =========================================================

if command -v rpm-ostree >/dev/null 2>&1; then
  echo "⚠️  This looks like a Fedora Atomic/Immutable system (rpm-ostree found)."
  echo "    Use your original script instead. Exiting."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "⚠️  Please run this script as a regular user (sudo will be used when needed)."
  exit 1
fi

echo "==> Updating system with dnf..."
sudo dnf -y upgrade --refresh

echo "==> Installing base CLI packages..."
sudo dnf -y install \
  zsh vim neovim fzf ripgrep yq \
  tealdeer \
  clamav clamav-update \
  bat socat xclip xsel \
  git curl wget unzip tar which

mkdir -p ~/.config/tealdeer
tldr --update || true

mkdir -p ~/.vim/undo

if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
  echo "==> Changing default shell to zsh (you'll need to log out/in)..."
  chsh -s "$(command -v zsh)"
fi


echo "==> Installing zsh plugins..."
mkdir -p ~/.zsh
if [[ ! -d ~/.zsh/zsh-autosuggestions ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
fi
if [[ ! -d ~/.zsh/zsh-syntax-highlighting ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
fi
if [[ ! -d ~/.zsh/zsh-autocomplete ]]; then
  git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete
fi

echo "==> Installing default programs"
sudo dnf -y install \
    seahorse filezilla wireshark\
    openscad eog
    
# VSCodium
sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n" | sudo tee -a /etc/yum.repos.d/vscodium.repo
sudo dnf -y install codium

# Proton Mail Bridge
wget https://proton.me/download/bridge/protonmail-bridge-3.13.0-1.x86_64.rpm
sudo dnf -y install ./protonmail-bridge-3.13.0-1.x86_64.rpm
rm protonmail-bridge-3.13.0-1.x86_64.rpm

# Proton VPN
wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
sudo dnf -y install ./protonvpn-stable-release-1.0.3-1.noarch.rpm && sudo dnf -y check-update --refresh 
sudo dnf -y install proton-vpn-gnome-desktop 
rm protonvpn-stable-release-1.0.3-1.noarch.rpm

echo "==> Ensuring Flatpak + Flathub..."
sudo dnf -y install flatpak
if ! flatpak remote-list | grep -qi flathub; then
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

flatpaks=(
  # org.kde.labplot
  # me.proton.Pass
  md.obsidian.Obsidian
  # org.gimp.GIMP
  # com.jgraph.drawio.desktop
)

echo "==> Installing Flatpaks (will skip if present)..."
for pkg in "${flatpaks[@]}"; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  echo "📦 flatpak install $pkg"
  flatpak install -y flathub "$pkg" || echo "⚠️  Flatpak install failed/skipped: $pkg"
done

echo "==> Installing general dev tools..."
# sudo dnf -y groupinstall "Development Tools" # gcc, make, etc.
sudo dnf -y install \
  gcc-c++ clang cmake ninja-build ccache cppcheck gdb valgrind \
  thefuck pandoc plantuml shc \
  nodejs yarnpkg \
  java-21-openjdk java-21-openjdk-devel maven \
  python3-pip python3-virtualenv \
  git-lfs
sudo dnf copr enable atim/lazygit
sudo dnf install -y lazygit

# echo "==> Installing texlive"
# this is LARGE, ~7+ GB
# sudo dnf -y install texlive-scheme-full

echo "==> Installing mobile tools (host)..."
sudo dnf -y install android-tools
sudo dnf copr enable zeno/scrcpy
sudo dnf -y install scrcpy

# --- Version managers (pyenv, rbenv) ---
echo "==> Setting up jabba"
curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash

if ! grep -q 'JABBA_HOME' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'EOF'
  
# Jabba (Java version manager)
export JABBA_HOME="$HOME/.jabba"
[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"
EOF
fi

echo "==> Setting up pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
  git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
fi

if ! grep -q 'PYENV_ROOT' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
EOF
fi

echo "==> Setting up rbenv..."
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  mkdir -p "$HOME/.rbenv/plugins"
  git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
fi

if ! grep -q 'rbenv init' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'EOF'

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi
EOF
fi

# --- Node Version Manager (nvm) ---
echo "==> Setting up nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

if ! grep -q 'NVM_DIR="$HOME/.nvm"' ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'EOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi
if ! grep -q 'NVM_DIR="$HOME/.nvm"' ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<'EOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi

# echo "==> Enabling clamav service"
# sudo systemctl enable --now clamav-freshclam.service

echo
echo "✅ All set for Fedora!"










