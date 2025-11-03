##########
# ENV
##########
export EDITOR=vim
export VISUAL=vim
CONFIG_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

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
alias code='codium'

# Docker
alias compose_up='docker-compose up && docker-compose rm -fsv'

# ESP-IDF
alias get_idf='. $HOME/esp/esp-idf/export.sh'

# 7Zip (Brew)
alias 7zip="7zz"
alias 7z="7zz"

# ADB
adb() {
    case "$1" in
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

# Proxy
#alias proxy='socat TCP-LISTEN:5555,fork TCP:192.168.3.97:5555'

# Files
alias projects='[ -d "$HOME/Projects" ] && cd "$HOME/Projects" || { [ -d "$HOME/Work" ] && cd "$HOME/Work" || echo "unknown directory"; }'
alias hosts='vim $HOME/.ssh/known_hosts'
alias vimrc='vim $HOME/.vimrc'
alias zshrc='vim $HOME/.zshrc'
alias zshsrc='source $HOME/.zshrc'
alias sshrc='vim $HOME/.ssh/config'
alias o="open"

##########
# Keybinds
##########
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
bindkey -v #-e for emacs style keybindings; -v for vim like keybindings

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
#zsh completion
autoload -Uz compinit
compinit

# case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# use completion menu
zstyle ':completion:*' menu select

# fuzzy completion
# generated using $(brew --prefix)/opt/fzf/install needs brew install fzf
[ -f "$CONFIG_DIR/fzf.zsh" ] && source "$CONFIG_DIR/fzf.zsh"

# ITerm2
test -e "$CONFIG_DIR/iterm2_shell_integration.zsh" && source "$CONFIG_DIR/iterm2_shell_integration.zsh"

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

export IDF_PATH="$HOME/esp/esp_idf"

#Plugins
source  $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source  $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

logcat_analyse() {
  pid="$1"
  file="$2"
  grep -E "^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+${pid}\>|^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}[[:space:]]+[0-9]+[[:space:]]+${pid}\>" "$file"
}

update_and_clean(){
 brew update && brew upgrade && brew cleanup -s
}



