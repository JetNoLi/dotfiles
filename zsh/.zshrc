# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
export XDG_CONFIG_HOME="$HOME/.config"

# Claude Code: stop it capturing the mouse so the wheel scrolls tmux, not the transcript
export CLAUDE_CODE_DISABLE_MOUSE=1

if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# PATH
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$(go env GOPATH)/bin"
export PATH="$PATH:/Applications/Tailscale.app/Contents/MacOS"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Configure Cargo
. "$HOME/.cargo/env"

# SET SHELL TO VIM MODE
zinit light jeffreytse/zsh-vi-mode
# zsh-vi-mode sets up its keymaps on the first prompt and would overwrite
# fzf's Ctrl-T/Ctrl-R/Alt-C widgets, so fzf and custom binds load in its hook.
zvm_after_init() {
  source <(fzf --zsh)
  bindkey '^y' autosuggest-accept
}
export VISUAL=nvim
export EDITOR=nvim


# THEMING CONFIG
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/zen.json)"


# FZF CONFIG
export FZF_DEFAULT_COMMAND='
  fd --type f --hidden \
     --exclude .git \
     --exclude node_modules \
     --exclude "Library"
'
export FZF_ALT_C_COMMAND='
  fd --type d --hidden \
     --exclude .git \
     --exclude "Library"
'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS='--tiebreak=begin,length --algo=v2'
export FZF_DEFAULT_SORT=10000

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# PLUGINS
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting


# Load completions
autoload -Uz compinit && compinit


eval "$(zoxide init zsh)"

## ALIASES
alias vim="nvim"
alias lz="lazygit"
alias ld="lazydocker"

#Script Aliases
alias s="~/.config/scripts/tmux/session.sh"
alias N="~/.config/scripts/tmux/notes.sh"
alias n="~/Desktop/Projects/go-notes/notes.exe"

# Machine-local extras
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
