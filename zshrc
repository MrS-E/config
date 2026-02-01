##########
# ENV
##########
export EDITOR=vim
export VISUAL=vim
ZSHRC_PATH="$(realpath "${(%):-%x}")"
CONFIG_DIR="$(dirname "$ZSHRC_PATH")"

##########
# History
##########

HISTFILE=~/.zsh_history
HISTSIZE=100000000
SAVEHIST=100000000
setopt SHARE_HISTORY

##########
# Alias
##########
# Navigation
alias ll="ls -al"
alias l='ls -lah'
alias la='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias pwdcpy="pwd | pbcopy"

# Grep
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias rgrep='grep -rin'

#FZF
alias fzfile='rg --no-heading --line-number "" | fzf' # ripgrep and fuzyfind needed

# SSH
alias sshproxy='ssh -D 8080 -C -N'
alias sshdisconnect='rm /tmp/ssh*'

# Git 
alias branch='git branch'
alias clone='git clone'
alias glog='git log --graph --abbrev-commit --decorate --all --oneline'
alias main='git switch main'
alias merge='git mergetool'
alias pull='git pull origin'
alias push='git push'
alias stash='git stash'
alias suba='git submodule add'
alias subi='git submodule init'
alias subu='git submodule update'
alias swi='git switch'
alias swic='git switch -c'
alias gittree="git log --graph --decorate --oneline"
alias lazy=lazygit

# Rails 
# alias rg='rails generate'
# alias rg:mo='rg model'
# alias rg:mi='rg migration'
# alias rg:v='rg view'
# alias rg:c='rg controller'
# alias rdb:c='rails db:create'
# alias rdb:d='rails db:drop'
# alias rdb:s='rails db:seed'
# alias rdb:m='rails db:migrate'
# alias rdb:cms='rails db:create db:migrate db:seed'

# History
alias shistory="history 0 | grep"

# Codium
alias co='codium'

# Docker
# alias compose_up='docker-compose up && docker-compose rm -fsv'
# alias docker_mounts="docker inspect $(docker ps -q) | jq '.[] | {container: .Name, mounts: .Mounts}'"

# 7Zip (Brew)
alias 7zip="7zz"
alias 7z="7zz"

# Proxy
# alias proxy='socat TCP-LISTEN:5555,fork TCP:192.168.3.97:5555'

# Files
alias vimrc='vim $HOME/.vimrc'
alias zshrc='vim $HOME/.zshrc'
alias zshsrc='source $HOME/.zshrc'
alias sshrc='vim $HOME/.ssh/config'
alias hosts='vim $HOME/.ssh/known_hosts'
alias o="open"

##########
# Keybinds
##########
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
# bindkey -v # - e for emacs style keybindings; -v for vim like keybindings

function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]]; then
    echo -ne '\e]0;NORMAL MODE\a'
  else
    echo -ne '\e]0;INSERT MODE\a'
  fi
}
zle -N zle-keymap-select

# inline command edit
autoload edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line

##########
# Style
##########
# zsh completion
autoload -Uz compinit
compinit

# case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# use completion menu
zstyle ':completion:*' menu select

# fuzzy completion
# generated using $(brew --prefix)/opt/fzf/install needs brew install fzf
[ -f "$CONFIG_DIR/fzf.zsh" ] && source "$CONFIG_DIR/fzf.zsh"

##########
# Patter Matching
##########
# setopt extended_glob

##########
# Promt
##########
precmd_functions=(render_prompt)

function render_prompt {
  # Start with an empty prompt
  PROMPT="" 
  # If there's exactly one background job, show a bold %
  PROMPT+="%(1j.%B%%%b .)"
  # Show current directory, using ~ for home
  PROMPT+="%~ "
  # If last command succeeded, prompt is green; if failed, red. Show bold $
  PROMPT+="%(?.%F{green}.%F{red})%B$%b%f "
  # On the right, show red exit code in brackets if last command failed
  RPROMPT="%(?..%F{red}[%?]%f)"
}

##########
# Homebrew
##########
if ! command -v brew &> /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)" # for Apple Silicon
  eval "$(/usr/local/bin/brew shellenv)"    # for Intel
fi

# NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# PYENV
eval "$(pyenv init --path)"

# Added by Toolbox App
export PATH="$PATH:/usr/local/bin"

# RVM
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# Zephyr-SDK
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.1"

# GNU grep
export PATH="$PATH: $(brew --prefix)/opt/grep/libexec/gnubin"

#TheFuck
eval $(thefuck --alias)

##########
# ZSH-Plugins
##########
source  $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source  $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

##########
# Scripts
##########

# ADB/logcat
adb() {
    case "$1" in
        loganal)
          shift
          if [ -z "$1" && -z "$2"]; then
              echo "Usage: adb loganal <pid> <path>"
              return 1
          fi
          pid="$1"
          file="$2"
          grep -E "^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+${pid}\>|^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+[0-9]+[[:space:]]+${pid}\>" "$file"
          ;;
        packcat)
          shift
          if [ -z "$1" ]; then
              echo "Usage: adb packcat <package.name> [logcat args]"
              return 1
          fi
          pkg="$1"
          shift
          pid=$(command adb shell pidof "$pkg")
          if [ -z "$pid" ]; then
              echo "Process for package '$pkg' not found."
              return 1
          fi
          command adb logcat --pid="$pid" "$@"
          ;;
        screen)
          shift
          scrcpy --video-codec=h265 -m1024 --max-fps=60 --no-audio -K "$@"
          ;;
        *)
          command adb "$@"
          ;;
    esac
}

# Homebrew
brew(){
  case "$1" in
    fullupgrade)
      brew update && brew upgrade && brew cleanup -s
      ;;
    file)
      shift
      local brewfile="${1:-Brewfile}"
      local backup="${brewfile}.old"
      if [[ -f "$brewfile" ]]; then
        if [[ -f "$backup" ]]; then
          mv "$brewfile" "${backup}.$(date +%Y%m%d%H%M%S)"
        else
          mv "$brewfile" "$backup"
        fi
      fi
      brew bundle dump --file="$brewfile" --describe --force
      ;;
    *)
      command brew "$@"
      ;;
  esac
}

# Projects
source "$CONFIG_DIR/scripts/project.sh"

# ESP-IDF
idf(){
  case "$1" in
  get)
    . $HOME/esp/esp-idf/export.sh
    ;;
  use)
    shift
    if [ -z "$1" ]; then
        echo "Usage: idf use <version>"
        echo "Example: idf use v5.4.2"
        return 1
    fi

    VERSION="$1"
    ESP_ROOT="$HOME/esp"
    IDF_DIR="$ESP_ROOT/esp-idf-$VERSION"

    mkdir -p "$ESP_ROOT"

    echo "Using ESP-IDF version $VERSION"
    if [ ! -d "$IDF_DIR" ]; then
        echo "Cloning ESP-IDF $VERSION into $IDF_DIR"
        git clone --recursive https://github.com/espressif/esp-idf.git "$IDF_DIR"
    fi
    cd "$IDF_DIR"

    echo "Fetching updates"
    git fetch --all --tags

    echo "Checking out $VERSION"
    git checkout "$VERSION"

    echo "Cleaning previous submodules"
    git submodule deinit -f --all || true
    git reset --hard
    git clean -fdx

    echo "Updating submodules"
    git submodule update --init --recursive

    echo "Installing tools + Python env"
    ./install.sh

    echo "Activating ESP-IDF environment"
    . ./export.sh

    echo "ESP-IDF ready: $(idf.py --version)"
    ;;
  *)
    if command -v idf.py >/dev/null 2>&1; then
      idf.py "$@"
      return $?
    fi

    local export_sh="$HOME/esp/esp-idf/export.sh"
    if [[ -f "$export_sh" ]]; then
      . "$export_sh"
    else
      echo "idf: idf.py not found and export script missing: $export_sh" >&2
      return 127
    fi

    if command -v idf.py >/dev/null 2>&1; then
      idf.py "$@"
    else
      echo "idf: idf.py still not found after sourcing $export_sh" >&2
      return 127
    fi
    ;;
  esac
}

code(){
  case "$1" in
  export)
    shift 
    if [ -z "$1" ]; then
      echo "Usage: code export <path>"
      return 1
    fi

    local dst_dir="$1"
    local user_dir="$HOME/Library/Application Support/VSCodium/User"
    local src_settings="$user_dir/settings.json"
    local dst_settings="$dst_dir/settings.json"
    local dst_exts="$dst_dir/extensions"

    local codium_bin=""
    if command -v codium >/dev/null 2>&1; then
      codium_bin="codium"
    elif [[ -x "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
      codium_bin="/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
    elif [[ -x "$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
      codium_bin="$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
    else
      echo "vscodium_export: couldn't find 'codium' CLI. Install it or ensure VSCodium.app exists in /Applications." >&2
      return 127
    fi

    mkdir -p "$dst_dir"

    if [[ -f "$src_settings" ]]; then
      cp -f "$src_settings" "$dst_settings"
      echo "Exported settings -> $dst_settings"
    else
      echo "vscodium_export: no settings.json found at: $src_settings (skipping settings export)" >&2
    fi

    "$codium_bin" --list-extensions | LC_ALL=C sort > "$dst_exts"
    echo "Exported extensions -> $dst_exts"
    ;;
  import)
    shift
    if [ -z "$1" ]; then
      echo "Usage: code import <path>"
      return 1
    fi

    local src_dir="$1"
    local src_settings="$src_dir/settings.json"
    local src_exts="$src_dir/extensions"

    local user_dir="$HOME/Library/Application Support/VSCodium/User"
    local dst_settings="$user_dir/settings.json"

    local codium_bin=""
    if command -v codium >/dev/null 2>&1; then
      codium_bin="codium"
    elif [[ -x "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
      codium_bin="/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
    elif [[ -x "$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
      codium_bin="$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
    else
      echo "vscodium_import: couldn't find 'codium' CLI. Install it or ensure VSCodium.app exists in /Applications." >&2
      return 127
    fi

    if [[ ! -f "$src_settings" ]]; then
      echo "vscodium_import: missing $src_settings" >&2
      return 2
    fi
    mkdir -p "$user_dir"
    cp -f "$src_settings" "$dst_settings"
    echo "Imported settings -> $dst_settings"

    if [[ ! -f "$src_exts" ]]; then
      echo "vscodium_import: missing $src_exts (skipping extensions install)" >&2
      return 0
    fi

    echo "Installing extensions from -> $src_exts"
    local line ext
    while IFS= read -r line || [[ -n "$line" ]]; do
      ext="${line%%#*}"
      ext="$(echo "$ext" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      [[ -z "$ext" ]] && continue

      echo "  + $ext"
      "$codium_bin" --install-extension "$ext" --force >/dev/null
    done < "$src_exts"

    echo "Done."
    ;;
  *)
    command codium "$@"
    ;;
  esac
}