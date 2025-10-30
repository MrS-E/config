#!/bin/bash

# --- utility ---
sudo rpm-ostree upgrade
sudo rpm-ostree install zsh vim neovim fzf ripgrep fzf yq tldr clamav clamav-update bat socat xclip xsel
systemctl reboot

# --- default shell ---
chsh -s $(which zsh)
systemctl reboot

# --- zsh plugins ---
mkdir -p ~/.zsh
cd ~/.zsh
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete

# --- Flatpak ---
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

PACKAGES=(
org.mozilla.Thunderbird
com.spotify.Clientd
net.cozic.joplin_desktop
# com.hunterwittenborn.Celeste
# com.rstudio.RStudio
com.getpostman.Postman
com.logseq.Logseq
org.zotero.Zotero
org.filezillaproject.Filezilla
# org.kde.labplot
ch.protonmail.protonmail-bridge
com.protonvpn.www
# me.proton.Pass
md.obsidian.Obsidian
org.wireshark.Wireshark
org.openscad.OpenSCAD
org.gimp.GIMP
# com.jgraph.drawio.desktop
com.vscodium.codium
org.gnome.seahorse.Application
io.github.woelper.Oculante
)

for pkg in "${PACKAGES[@]}"; do
  # Skip commented or empty entries
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

  echo "📦 Installing $pkg..."
  flatpak install -y "$pkg" || {
    echo "⚠️  Failed to install $pkg"
  }
done

# --- Toolboxes ---
tb_run () {
  local name="$1"; shift
  toolbox run --container "$name" bash -lc "$*"
}

echo "==> Creating toolboxes (safe if they already exist)..."
toolbox create --container cpp-dev   || true
toolbox create --container latex     || true
toolbox create --container mobile    || true
toolbox create --container cli-dev   || true

# --- C/C++ Toolbox ---
echo "==> Configuring cpp-dev..."
tb_run cpp-dev '
  sudo dnf -y upgrade
  sudo dnf -y install \
    gcc gcc-c++ \
    llvm clang \
    cmake make ninja-build \
    ccache cppcheck \
    gdb valgrind
'

# --- LaTeX Toolbox ---
echo "==> Configuring latex..."
tb_run latex '
  sudo dnf -y upgrade
  # Fedora uses texlive-collection-* metas instead of Arch names.
  sudo dnf -y install \
    texlive \
    texlive-collection-basic \
    texlive-collection-latex \
    texlive-collection-latexrecommended \
    texlive-collection-fontsrecommended \
    texlive-xetex \
    texlive-luatex \
    texlive-bibtex-bin \
    texlive-babel-english texlive-babel-german \
    hyphen-english hyphen-german \
    java-21-openjdk wget tar pandoc

  # Install LTEX Language Server (no Fedora RPM)
  mkdir -p "$HOME/.local/share/ltex-ls"
  cd "$HOME/.local/share/ltex-ls"
  # Grab latest release tarball
  LTX_URL="$(curl -sL https://api.github.com/repos/valentjn/ltex-ls/releases/latest \
    | grep -Eo \"https.*linux-x64\.tar\.gz\")"
  wget -q \"$LTX_URL\" -O ltex-ls.tar.gz
  rm -rf ltex-ls && mkdir -p ltex-ls
  tar xzf ltex-ls.tar.gz -C ltex-ls --strip-components=1
  echo \"LTEX LS installed at: \$HOME/.local/share/ltex-ls/bin/ltex-ls\"
'

# --- Mobile Toolbox ---
echo "==> Configuring mobile..."
tb_run mobile '
  sudo dnf -y upgrade
  sudo dnf clean all && sudo dnf makecache
  # Android tools from Fedora
  sudo dnf -y install android-tools scrcpy unzip curl

  # ktlint (upstream release JAR/binary)
  mkdir -p "$HOME/bin"
  curl -fsSL -o "$HOME/bin/ktlint" \
    https://github.com/pinterest/ktlint/releases/latest/download/ktlint
  chmod +x "$HOME/bin/ktlint"

  # swiftlint (portable Linux binary from upstream)
  mkdir -p "$HOME/opt" "$HOME/bin"
  cd "$HOME/opt"
  # Some releases publish a zip named portable_swiftlint_linux.zip
  curl -fsSL -o portable_swiftlint_linux.zip \
    https://github.com/realm/SwiftLint/releases/latest/download/portable_swiftlint_linux.zip
  rm -rf swiftlint && mkdir swiftlint
  unzip -o portable_swiftlint_linux.zip -d swiftlint >/dev/null
  ln -sf "$HOME/opt/swiftlint/swiftlint" "$HOME/bin/swiftlint"

  # Ensure ~/bin is in PATH for this toolbox sessions
  if ! grep -q \"export PATH=\\\"\\$HOME/bin:\\$PATH\\\"\" ~/.bashrc 2>/dev/null; then
    echo \"export PATH=\\\"\\$HOME/bin:\\$PATH\\\"\" >> ~/.bashrc
  fi
  if ! grep -q \"export PATH=\\\"\\$HOME/bin:\\$PATH\\\"\" ~/.zshrc 2>/dev/null; then
    echo \"export PATH=\\\"\\$HOME/bin:\\$PATH\\\"\" >> ~/.zshrc
  fi
'

# --- CLI Dev Toolbox ---
echo "==> Configuring cli-dev..."
tb_run cli-dev '
  sudo dnf -y upgrade
  sudo dnf -y install \
    java-21-openjdk \
    thefuck \
    pandoc \
    plantuml \
    shc \
    yarnpkg \
    python3-pip git curl unzip

  # Version managers (installed into $HOME)
  # jabba (Java)
  if [ ! -d \"$HOME/.jabba\" ]; then
    curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash
    echo '\''[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"'\'' >> ~/.zshrc
    echo '\''[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"'\'' >> ~/.bashrc
  fi

  # pyenv (Python)
  if [ ! -d \"$HOME/.pyenv\" ]; then
    curl -fsSL https://pyenv.run | bash
    echo '\''export PATH="$HOME/.pyenv/bin:$PATH"'\'' >> ~/.zshrc
    echo '\''eval "$(pyenv init -)"'\'' >> ~/.zshrc
    echo '\''export PATH="$HOME/.pyenv/bin:$PATH"'\'' >> ~/.bashrc
    echo '\''eval "$(pyenv init -)"'\'' >> ~/.bashrc
  fi

  # nvm (Node)
  if [ ! -d \"$HOME/.nvm\" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    echo '\''export NVM_DIR="$HOME/.nvm"'\'' >> ~/.zshrc
    echo '\''[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'\'' >> ~/.zshrc
    echo '\''export NVM_DIR="$HOME/.nvm"'\'' >> ~/.bashrc
    echo '\''[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'\'' >> ~/.bashrc
  fi
'

echo "✅ All toolboxes configured!"
echo "   - cpp-dev   : gcc/clang/cmake/ninja/ccache/cppcheck/gdb/valgrind"
echo "   - latex     : TeX Live collections + LTEX LS (Java 21)"
echo "   - mobile    : android-tools, scrcpy, ktlint, swiftlint"
echo "   - cli-dev   : thefuck, pandoc, plantuml, shc, yarnpkg, Java 21 + version managers"

