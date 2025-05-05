# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
#. export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-~/.config}"
export XDG_CONFIG_HOME="$HOME/.config"

export PATH=$PATH:$(go env GOPATH)/bin

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Configure Cargo
. "$HOME/.cargo/env"

# SET SHELL TO VIM MODE
# set -o vi
# zinit ice depth=1
zinit load jeffreytse/zsh-vi-mode
export visual=nvim
export EDITOR=nvim


# THEMING CONFIG
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/zen.json)"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh)"
fi


# FZF CONFIG
# eval "$(fzf --zsh)"
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='
  fd --type f --hidden \
     --exclude .git \
     --exclude "Library" .
'
export FZF_ALT_C_COMMAND='
  fd --type d --hidden \
     --exclude .git \
     --exclude "Library" .
'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS='--tiebreak=begin,length --algo=v2'
export FZF_DEFAULT_SORT=10000

# PLUGINS
zinit load zsh-users/zsh-autosuggestions
zinit load zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting


# Load completions
autoload -Uz compinit && compinit


eval "$(zoxide init zsh)"

## ALIASES
alias vim="nvim"
alias lz="lazygit"
alias ld="lazydocker"

