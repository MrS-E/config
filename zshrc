##########
# ENV
##########
export EDITOR=vim
export VISUAL=vim

# Path of this config file / directory (works when sourced by zsh)
ZSHRC_PATH="${${(%):-%N}:A}"
CONFIG_DIR="${ZSHRC_PATH:h}"
DIR="$CONFIG_DIR"

##########
# OS + Hardware Detection
##########
case "$(uname -s)" in
  Darwin)
    export OS="macos"

    case "$(uname -m)" in
      arm64)  export MAC_ARCH="arm64" ;;
      x86_64) export MAC_ARCH="x86_64" ;;
      *)      export MAC_ARCH="unknown" ;;
    esac

    export MAC_RAM_GB="$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))"
    ;;
  Linux)
    export OS="linux"

    : "${XDG_SESSION_TYPE:=}"

    case "$(uname -m)" in
      x86_64) export LINUX_ARCH="x86_64" ;;
      armv7l) export LINUX_ARCH="armv7l" ;;
      aarch64) export LINUX_ARCH="arm64" ;;
      *)      export LINUX_ARCH="unknown" ;;
    esac

    if [[ -r /proc/meminfo ]]; then
      export LINUX_RAM_GB="$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))"
    fi
    ;;
  *)
    export OS="unknown"
    ;;
esac

#########
# History
##########
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
setopt SHARE_HISTORY

##########
# Alias
##########
# Navigation
alias ll='ls -al'
alias l='ls -lah'
alias la='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'

# Clipboard / platform helpers
clip() {
  if [[ "$OS" = "macos" ]] && command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif [[ "$OS" = "linux" ]]; then
    if [[ "$XDG_SESSION_TYPE" = "wayland" ]] && command -v wl-copy >/dev/null 2>&1; then
      wl-copy
    elif command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
      xsel --clipboard --input
    else
      echo "clip(): no clipboard tool found (install wl-clipboard, xclip, or xsel)" >&2
      return 1
    fi
  else
    echo "Unsupported OS for clip()" >&2
    return 1
  fi
}
alias copy='clip'
alias pwdcpy='pwd | clip'

clippaste() {
  if [[ "$OS" = "macos" ]] && command -v pbpaste >/dev/null 2>&1; then
    pbpaste
  elif [[ "$OS" = "linux" ]]; then
    if [[ "$XDG_SESSION_TYPE" = "wayland" ]] && command -v wl-paste >/dev/null 2>&1; then
      wl-paste
    elif command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard -o
    elif command -v xsel >/dev/null 2>&1; then
      xsel --clipboard --output
    elif command -v wl-paste >/dev/null 2>&1; then
      wl-paste
    else
      echo "clippaste(): no clipboard tool found" >&2
      return 1
    fi
  else
    echo "Unsupported OS for clippaste()" >&2
    return 1
  fi
}
alias paste='clippaste'

# Open current file/url in platform default opener
o() {
  if [[ "$OS" = "macos" ]] && command -v open >/dev/null 2>&1; then
    open "$@"
  elif [[ "$OS" = "linux" ]] && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$@"
  else
    echo "No platform opener available" >&2
    return 1
  fi
}

# Grep
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias rgrep='grep -rin'

# FZF
alias fzfile='rg --no-heading --line-number "" | fzf'

# SSH
alias sshproxy='ssh -D 8080 -C -N'
alias sshdisconnect='rm -f /tmp/ssh*'

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
alias gittree='git log --graph --decorate --oneline'
alias lazy='lazygit'

# Rails 
alias rg:mo='rails generate model'
alias rg:mi='rails generate migration'
alias rg:v='rails generate view'
alias rg:c='rails generate controller'
alias rdb:c='rails db:create'
alias rdb:d='rails db:drop'
alias rdb:s='rails db:seed'
alias rdb:m='rails db:migrate'
alias rdb:cms='rails db:create db:migrate db:seed'

# History
alias shistory='history 0 | grep'

# Codium
alias co='codium'

# 7Zip
alias 7zip='7zz'
alias 7z='7zz'

# Files
alias vimrc='vim $HOME/.vimrc'
alias zshrc='vim $HOME/.zshrc'
alias zshsrc='source $HOME/.zshrc'
alias sshrc='vim $HOME/.ssh/config'
alias hosts='vim $HOME/.ssh/known_hosts'

##########
# Completion
##########
autoload -Uz compinit
zmodload zsh/complist
compinit

# bash completions into zsh
if [[ -d /usr/share/bash-completion/completions ]]; then
  autoload -Uz bashcompinit
  bashcompinit

  local -a bashcomp_cmds
  bashcomp_cmds=(
    git
    curl
    wget
    ssh
    rsync
    kubectl
    docker
    docker-compose
    podman
    podman-compose
    pip
    pip3
  )

  for cfile in /usr/share/bash-completion/completions/*(.N); do
    cmd=${cfile:t}
    if (( ${bashcomp_cmds[(Ie)$cmd]} == 0 )); then
      continue
    fi
    command -v "$cmd" >/dev/null 2>&1 || continue
    if grep -qE '\b(compopt|_init_completion|declare -A|shopt|_comp_have_command|check_type)\b' "$cfile"; then
      continue
    fi
    source "$cfile"
  done
fi

[[ -d /usr/share/zsh/site-functions ]] && FPATH="/usr/share/zsh/site-functions:$FPATH"

if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

##########
# Keybinds
##########
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
# bindkey -v

function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]]; then
    echo -ne '\e]0;NORMAL MODE\a'
  else
    echo -ne '\e]0;INSERT MODE\a'
  fi
}
zle -N zle-keymap-select

autoload edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line

##########
# Style
##########
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# ITerm2 integration on macOS
if [[ "$OS" = "macos" ]]; then
  [[ -e "$DIR/iterm2_shell_integration.zsh" ]] && source "$DIR/iterm2_shell_integration.zsh"
fi

##########
# Prompt
##########
precmd_functions=(render_prompt)

function render_prompt {
  PROMPT=""
  PROMPT+="%(1j.%B%%%b .)"
  PROMPT+="%~ "
  PROMPT+="%(?.%F{green}.%F{red})%B$%b%f "
  RPROMPT="%(?..%F{red}[%?]%f)"
}

##########
# Homebrew
##########
if ! command -v brew >/dev/null 2>&1; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

##########
# FZF
##########

if (( $+commands[brew] )); then
  BREW_PREFIX="$(brew --prefix 2>/dev/null)"
  if [[ -n "$BREW_PREFIX" && -d "$BREW_PREFIX/opt/fzf/bin" && ":$PATH:" != *":$BREW_PREFIX/opt/fzf/bin:"* ]]; then
    export PATH="$BREW_PREFIX/opt/fzf/bin:$PATH"
  fi
fi

if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

##########
# Jetbrains Toolbox
##########

export PATH="$PATH:/usr/local/bin"

##########
# NVM
##########
if [[ -s /usr/share/nvm/init-nvm.sh ]]; then
  export NVM_DIR="$HOME/.nvm"
  source /usr/share/nvm/init-nvm.sh
  [[ -s /usr/share/nvm/bash_completion ]] && source /usr/share/nvm/bash_completion
elif command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix 2>/dev/null)/opt/nvm" ]]; then
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]] && source "$(brew --prefix)/opt/nvm/nvm.sh"
  [[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ]] && source "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

##########
# JABBA
##########
if [[ -s "$HOME/.jabba/jabba.sh" ]]; then
  export JABBA_INDEX="https://github.com/typelevel/jdk-index/raw/main/index.json"
  export JABBA_HOME="$HOME/.jabba"
  source "$JABBA_HOME/jabba.sh"
fi

##########
# PYENV
##########
if [[ -d "$HOME/.pyenv/bin" ]]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv init --path)"
fi

##########
# RBENV
##########
if [[ -d "$HOME/.rbenv/bin" ]]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
fi

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

##########
# Zephyr-SDK
##########
# export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.1"

##########
# GNU grep (Homebrew)
##########
if command -v brew >/dev/null 2>&1; then
  export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"
fi

##########
# Tailscale
##########
if command -v tailscale >/dev/null 2>&1; then
  source <(tailscale completion zsh)
fi

##########
# TheFuck
##########
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi

##########
# ZSH Plugins
##########

# Prefer local clones if present
if [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif command -v brew >/dev/null 2>&1 && [[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -f "$HOME/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
  source "$HOME/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
fi

# Syntax highlighting should be last
if [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif command -v brew >/dev/null 2>&1 && [[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

##########
# Scripts
##########

# ADB/logcat
adb() {
  case "$1" in
    loganal)
      shift
      if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: adb loganal <pid> <path>"
        return 1
      fi
      local pid="$1"
      local file="$2"
      grep -E "^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+${pid}\>|^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+[0-9]+[[:space:]]+${pid}\>" "$file"
      ;;
    packcat)
      shift
      if [[ -z "$1" ]]; then
        echo "Usage: adb packcat <package.name> [logcat args]"
        return 1
      fi
      local pkg="$1"
      shift
      local pid
      pid=$(command adb shell pidof "$pkg")
      if [[ -z "$pid" ]]; then
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
if (( $+commands[brew] )); then
  brew() {
    case "$1" in
      fullupgrade)
        command brew update && command brew upgrade && command brew cleanup -s
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
        command brew bundle dump --file="$brewfile" --describe --force
        ;;
      *)
        command brew "$@"
        ;;
    esac
  }
fi 
# Projects
[[ -f "$CONFIG_DIR/scripts/project.sh" ]] && source "$CONFIG_DIR/scripts/project.sh"

# ESP-IDF
export IDF_PATH="$HOME/esp/esp-idf"
idf() {
  case "$1" in
    get)
      shift
      . "$IDF_PATH/export.sh"

      if command -v idf.py >/dev/null 2>&1 && [[ -n "${1-}" ]]; then
        idf.py "$@"
        return $?
      fi
      ;;
    trace)
      shift
      if [[ -z "$1" || -z "$2" ]]; then
        echo "Error: Missing arguments."
        echo 'Usage: idf trace path/to/project.elf "0x400...:0x3ff... 0x400..."'
        return 1
      fi

      local ELF_FILE="$1"
      local BACKTRACE="$2"

      if [[ ! -f "$ELF_FILE" ]]; then
        echo "Error: ELF file '$ELF_FILE' not found."
        return 1
      fi

      local ADDR2LINE="xtensa-esp32-elf-addr2line"

      if ! command -v "$ADDR2LINE" >/dev/null 2>&1; then
        echo "Info: $ADDR2LINE not found. Attempting to load ESP-IDF environment..."

        if [[ -f "$IDF_PATH/export.sh" ]]; then
          . "$IDF_PATH/export.sh" >/dev/null 2>&1
        else
          echo "Error: $ADDR2LINE is not in PATH and $IDF_PATH/export.sh was not found."
          echo "Please ensure ESP-IDF is installed and set correctly."
          return 1
        fi
      fi

      if ! command -v "$ADDR2LINE" >/dev/null 2>&1; then
        echo "Error: $ADDR2LINE is still not available after trying to source ESP-IDF."
        return 1
      fi

      echo "Decoding Backtrace using: $(basename "$ELF_FILE")"
      echo "------------------------------------------------"

      local entry addr
      for entry in ${(z)BACKTRACE}; do
        addr=$(echo "$entry" | cut -d':' -f1)
        "$ADDR2LINE" -pfiaC -e "$ELF_FILE" "$addr"
      done

      echo "------------------------------------------------"
      ;;
    use)
      shift
      if [[ -z "$1" ]]; then
        echo "Usage: idf use <version>"
        echo "Example: idf use v5.4.2"
        return 1
      fi

      local VERSION="$1"
      local ESP_ROOT="$HOME/esp"
      local IDF_DIR="$ESP_ROOT/esp-idf-$VERSION"

      mkdir -p "$ESP_ROOT"

      echo "Using ESP-IDF version $VERSION"
      if [[ ! -d "$IDF_DIR" ]]; then
        echo "Cloning ESP-IDF $VERSION into $IDF_DIR"
        git clone --recursive https://github.com/espressif/esp-idf.git "$IDF_DIR"
      fi
      cd "$IDF_DIR" || return 1

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

      local export_sh="$IDF_PATH/export.sh"
      if [[ -f "$export_sh" ]]; then
        . "$export_sh" >/dev/null 2>&1
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

code() {
  case "$1" in
    export)
      shift
      if [[ -z "$1" ]]; then
        echo "Usage: code export <path>"
        return 1
      fi

      local dst_dir="$1"
      local user_dir=""
      local src_settings=""
      local dst_settings="$dst_dir/settings.json"
      local dst_base="$dst_dir/settings.base.json"
      local dst_overlay=""
      local dst_exts="$dst_dir/extensions"

      case "$OS" in
        macos)
          user_dir="$HOME/Library/Application Support/VSCodium/User"
          dst_overlay="$dst_dir/settings.macos.json"
          ;;
        linux)
          user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"
          dst_overlay="$dst_dir/settings.linux.json"
          ;;
        *)
          echo "code export: unsupported OS '$OS'" >&2
          return 1
          ;;
      esac

      src_settings="$user_dir/settings.json"

      local codium_bin=""
      if command -v codium >/dev/null 2>&1; then
        codium_bin="codium"
      elif [[ -x "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
        codium_bin="/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
      elif [[ -x "$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
        codium_bin="$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
      else
        echo "code export: couldn't find 'codium' CLI." >&2
        return 127
      fi

      mkdir -p "$dst_dir"

      if [[ -f "$src_settings" ]]; then
        cp -f "$src_settings" "$dst_settings"
        echo "Exported full settings -> $dst_settings"

        if command -v jq >/dev/null 2>&1; then
          # Keys that should live in per-machine overlays
          local path_filter='
            del(
              ."markdown-preview-enhanced.plantumlJarPath",
              ."idf.pythonInstallPath",
              ."idf.espIdfPath",
              ."idf.toolsPath"
            )
          '

          local overlay_filter='
            {
              "markdown-preview-enhanced.plantumlJarPath": ."markdown-preview-enhanced.plantumlJarPath",
              "idf.pythonInstallPath": ."idf.pythonInstallPath",
              "idf.espIdfPath": ."idf.espIdfPath",
              "idf.toolsPath": ."idf.toolsPath"
            }
            | with_entries(select(.value != null))
          '

          jq "$path_filter" "$src_settings" > "$dst_base" &&
            echo "Exported shared settings -> $dst_base"

          jq "$overlay_filter" "$src_settings" > "$dst_overlay" &&
            echo "Exported OS overlay -> $dst_overlay"
        else
          echo "code export: jq not found; wrote only full settings backup -> $dst_settings" >&2
        fi
      else
        echo "code export: no settings.json found at: $src_settings (skipping settings export)" >&2
      fi

      "$codium_bin" --list-extensions | LC_ALL=C sort > "$dst_exts"
      echo "Exported extensions -> $dst_exts"
      ;;
    import)
      shift
      if [[ -z "$1" ]]; then
        echo "Usage: code import <path>"
        return 1
      fi

      local src_dir="$1"
      local src_settings="$src_dir/settings.json"
      local src_base="$src_dir/settings.base.json"
      local src_overlay=""
      local src_exts="$src_dir/extensions"
      local user_dir=""
      local dst_settings=""
      local codium_bin=""

      case "$OS" in
        macos)
          user_dir="$HOME/Library/Application Support/VSCodium/User"
          src_overlay="$src_dir/settings.macos.json"
          ;;
        linux)
          user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"
          src_overlay="$src_dir/settings.linux.json"
          ;;
        *)
          echo "code import: unsupported OS '$OS'" >&2
          return 1
          ;;
      esac

      dst_settings="$user_dir/settings.json"

      if command -v codium >/dev/null 2>&1; then
        codium_bin="codium"
      elif [[ -x "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
        codium_bin="/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
      elif [[ -x "$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
        codium_bin="$HOME/Applications/VSCodium.app/Contents/Resources/app/bin/codium"
      else
        echo "code import: couldn't find 'codium' CLI." >&2
        return 127
      fi

      mkdir -p "$user_dir"

      if [[ -f "$src_base" ]]; then
        if ! command -v jq >/dev/null 2>&1; then
          echo "code import: jq is required to merge settings.base.json with OS overlays." >&2
          return 2
        fi

        if [[ -f "$src_overlay" ]]; then
          jq -s '.[0] * .[1]' "$src_base" "$src_overlay" > "$dst_settings" || return 1
          echo "Imported merged settings -> $dst_settings"
          echo "  base:    $src_base"
          echo "  overlay: $src_overlay"
        else
          cp -f "$src_base" "$dst_settings"
          echo "Imported base settings only -> $dst_settings"
        fi
      elif [[ -f "$src_settings" ]]; then
        cp -f "$src_settings" "$dst_settings"
        echo "Imported full settings -> $dst_settings"
      else
        echo "code import: missing $src_base and $src_settings" >&2
        return 2
      fi

      if [[ ! -f "$src_exts" ]]; then
        echo "code import: missing $src_exts (skipping extensions install)" >&2
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
