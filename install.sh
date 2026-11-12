#!/usr/bin/env bash
# Mac bootstrap: install what's missing and symlink every stow package into
# $HOME. Idempotent — safe to re-run after adding a package.
set -euo pipefail
cd "$(dirname "$0")"

# Homebrew refuses to build/install until the Xcode license is accepted.
# Only full Xcode has a license; with just Command Line Tools there's nothing to accept.
if [[ "$(xcode-select -p 2>/dev/null)" == *Xcode.app* ]] && ! xcodebuild -license check >/dev/null 2>&1; then
  echo "Xcode license not accepted. Run this, then re-run ./install.sh:" >&2
  echo "  sudo xcodebuild -license accept" >&2
  exit 1
fi

command -v stow >/dev/null || brew install stow
command -v gh >/dev/null || brew install gh
# wb needs bash 5; macOS ships 3.2. Homebrew's lands first on PATH.
bash -c '[ "${BASH_VERSINFO[0]}" -ge 5 ]' || brew install bash
command -v fzf >/dev/null || brew install fzf
command -v fd >/dev/null || brew install fd
command -v jq >/dev/null || brew install jq
[ -d /Applications/Ghostty.app ] || brew install --cask ghostty

# tmux plugins — tpm lives under the XDG tree (tmux.conf sets
# TMUX_PLUGIN_MANAGER_PATH accordingly); the rest install with prefix+I.
[ -d ~/.config/tmux/plugins/tpm ] || \
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# -t "$HOME" so the target doesn't depend on where this repo is cloned.
# Stow stops on a conflict (e.g. a real ~/.gitconfig) rather than overwriting.
stow -t "$HOME" zsh tmux ohmyposh scripts aerospace ghostty git claude nvim

# wb's Claude Code hooks (agent status, pick-up), merged into its settings (not stowed).
scripts/.config/scripts/tmux/claude-hooks-merge.sh

echo "Done. Still needed by hand:"
command -v gh >/dev/null && gh auth status >/dev/null 2>&1 || echo "  - gh auth login"
[ -f ~/.gitconfig.local ] || echo "  - create ~/.gitconfig.local with your [user] name/email"
command -v claude >/dev/null || echo "  - install Claude Code (wb's agents and status need it)"
echo "  - open tmux and press <prefix> + I to install tmux plugins (if not already installed)"
echo "Machine-local shell extras go in ~/.zshrc.local."
