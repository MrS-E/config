##########
# ENV
##########
export EDITOR=vim
export VISUAL=vim

##########
# OS + Hardware Detection
##########
case "$(uname -s)" in
  Darwin)
    export OS="macos"

    # Arch: arm64 = Apple Silicon, x86_64 = Intel
    case "$(uname -m)" in
      arm64)  export MAC_ARCH="arm64" ;;  # Apple Silicon
      x86_64) export MAC_ARCH="x86_64" ;; # Intel
      *)      export MAC_ARCH="unknown" ;;
    esac

    # RAM in GiB (macOS: hw.memsize reports bytes)
    export MAC_RAM_GB="$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))"
    ;;
  Linux)
    export OS="linux"

    # Detect session type (Wayland/X11)
    : "${XDG_SESSION_TYPE:=}"

    # Arch
    case "$(uname -m)" in
      x86_64) export LINUX_ARCH="x86_64" ;;
      armv7l) export LINUX_ARCH="armv7l" ;;
      aarch64) export LINUX_ARCH="arm64" ;;
      *)      export LINUX_ARCH="unknown" ;;
    esac

    # RAM in GiB (Linux: /proc/meminfo reports kB)
    if [[ -r /proc/meminfo ]]; then
      export LINUX_RAM_GB="$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))"
    fi
    ;;
  *)
    export OS="unknown"
    ;;
esac

##########
# History
##########

HISTFILE=~/.zsh_history
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

# Grep
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias rgrep='grep -rin'

# SSH
alias sshproxy='ssh -D 8080 -C -N'

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
alias lazy=lazygit

# Rails 
alias rg='rails generate'
alias rg:mo='rg model'
alias rg:mi='rg migration'
alias rg:v='rg view'
alias rg:c='rg controller'
alias rdb:c='rails db:create'
alias rdb:d='rails db:drop'
alias rdb:s='rails db:seed'
alias rdb:m='rails db:migrate'
alias rdb:cms='rails db:create db:migrate db:seed'

# History
alias shistory="history 0 | grep"

# Codium
alias co='codium'
alias code='codium'

# Docker
# TODO make variable for podman with docker as fallback
alias compose_up='docker-compose up && docker-compose rm -fsv'

# ESP-IDF
alias get_idf='. $HOME/esp/esp-idf/export.sh'

# Proxy
#alias proxy='socat TCP-LISTEN:5555,fork TCP:192.168.3.97:5555'

# Apps & Files
alias projects='[ -d "$HOME/Projects" ] && cd "$HOME/Projects" || { [ -d "$HOME/Work" ] && cd "$HOME/Work" || echo "unknown directory"; }'
alias hosts='vim $HOME/.ssh/known_hosts'
alias vimrc='vim $HOME/.vimrc'
alias zshrc='vim $HOME/.zshrc'
alias zshsrc='source $HOME/.zshrc'
alias sshrc='vim $HOME/.ssh/config'
alias phone='scrcpy --video-codec=h265 -m1024 --max-fps=60 --no-audio -K'

##########
# Completion
##########
autoload -Uz compinit
zmodload zsh/complist
compinit

# if [[ -d /usr/share/bash-completion/completions ]]; then
#   autoload -U +X bashcompinit && bashcompinit
#   for cfile in /usr/share/bash-completion/completions/*(.N); do
#     cmd="${cfile:t}"
#     # only if the command exists
#     (( $+commands[$cmd] )) || continue
#     # skip scripts that require bash-only features
#     if grep -qE '\b(compopt|_init_completion|declare -A|shopt)\b' "$cfile"; then
#       continue
#     fi
#     source "$cfile"
#   done
# fi

# Arch system zsh site-functions (usually present by default)
[[ -d /usr/share/zsh/site-functions ]] && FPATH="/usr/share/zsh/site-functions:$FPATH"

# Homebrew (macOS or Linuxbrew) site-functions
if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

##########
# Keybinds
##########
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
bindkey -e

# inline command edit
autoload edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line

##########
# Style
##########
# case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# use completion menu
zstyle ':completion:*' menu select

# ITerm2
if [[ "$OS" = "macos" ]]; then
  [[ -e "iterm2_shell_integration.zsh" ]] && source "iterm2_shell_integration.zsh"
fi

##########
# Patter Matching
##########
#setopt extended_glob

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
# Tools
##########

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  # macOS (Intel & Apple Silicon)
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)" # Apple Silicon
  [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)" # Intel
  # Linuxbrew (Manjaro)
  [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
if [[ -s /usr/share/nvm/init-nvm.sh ]]; then
  # Arch/pacman package
  source /usr/share/nvm/init-nvm.sh
  [[ -s /usr/share/nvm/bash_completion ]] && source /usr/share/nvm/bash_completion
elif command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix 2>/dev/null)/opt/nvm" ]]; then
  # Homebrew
  [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]] && source "$(brew --prefix)/opt/nvm/nvm.sh"
  [[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ]] && source "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # Manual install
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# JABBA
export JABBA_INDEX='https://github.com/typelevel/jdk-index/raw/main/index.json'
[ -s "/home/sstix/.jabba/jabba.sh" ] && source "/home/sstix/.jabba/jabba.sh"

# PYENV
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"        # shells
  eval "$(pyenv init --path)"   # login shells
fi

# Jetbrains Toolbox
if [[ "$OS" = "macos" ]]; then
  export PATH="$PATH:/usr/local/bin"
fi

# RVM
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# Zephyr-SDK
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.1"

# GNU grep
if [[ "$OS" = "macos" ]] && command -v brew >/dev/null 2>&1; then
  GREP_GNUBIN="$(brew --prefix)/opt/grep/libexec/gnubin"
  [[ -d "$GREP_GNUBIN" ]] && export PATH="$PATH:$GREP_GNUBIN"
fi

#TheFuck
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi

##########
# Plugins
##########

# Load autosuggestions first
if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Load syntax highlighting (must come last!)
if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Load autocomplete
if [ -f ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]; then
  source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh
fi

##########
# Functions
##########

# Universal clipboard: macOS pbcopy; Linux Wayland/X11 fallback
clip() {
  if [[ "$OS" = "macos" ]] && command -v pbcopy >/dev/null 2>&1; then
    pbcopy "$@"
  elif [[ "$OS" = "linux" ]]; then
    if [[ "$XDG_SESSION_TYPE" = "wayland" ]] && command -v wl-copy >/dev/null 2>&1; then
      wl-copy "$@"
    elif [[ "$XDG_SESSION_TYPE" = "x11" ]] && command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard "$@"
    elif command -v wl-copy >/dev/null 2>&1; then
      wl-copy "$@"
    elif command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard "$@"
    else
      echo "No clipboard tool found (install wl-clipboard or xclip)." >&2
      return 1
    fi
  else
    echo "Unsupported OS for clip()" >&2
    return 1
  fi
}
alias copy='clip'

paste() {
  if [[ "$OS" = "macos" ]] && command -v pbpaste >/dev/null 2>&1; then
    pbpaste
  elif [[ "$OS" = "linux" ]]; then
    if [[ "$XDG_SESSION_TYPE" = "wayland" ]] && command -v wl-paste >/dev/null 2>&1; then
      wl-paste
    elif command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard -o
    elif command -v wl-paste >/dev/null 2>&1; then
      wl-paste
    else
      echo "No clipboard reader found (install wl-clipboard or xclip)." >&2
      return 1
    fi
  fi
}
alias paste='paste'

