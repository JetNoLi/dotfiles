#!/usr/bin/env bash
# Mac bootstrap: install what's missing and symlink every stow package into
# $HOME. Idempotent — safe to re-run after adding a package.
set -euo pipefail
cd "$(dirname "$0")"

# Homebrew refuses to build/install until the Xcode license is accepted.
if ! xcodebuild -license check >/dev/null 2>&1; then
  echo "Xcode license not accepted. Run this, then re-run ./install.sh:" >&2
  echo "  sudo xcodebuild -license accept" >&2
  exit 1
fi

command -v stow >/dev/null || brew install stow
command -v gh >/dev/null || brew install gh
[ -d /Applications/Ghostty.app ] || brew install --cask ghostty

# tmux plugins — tpm lives under the XDG tree (tmux.conf sets
# TMUX_PLUGIN_MANAGER_PATH accordingly); the rest install with prefix+I.
[ -d ~/.config/tmux/plugins/tpm ] || \
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# -t "$HOME" so the target doesn't depend on where this repo is cloned.
# Stow stops on a conflict (e.g. a real ~/.gitconfig) rather than overwriting.
stow -t "$HOME" zsh tmux ohmyposh scripts aerospace ghostty git

echo "Done. Still needed by hand:"
command -v gh >/dev/null && gh auth status >/dev/null 2>&1 || echo "  - gh auth login"
[ -f ~/.gitconfig.local ] || echo "  - create ~/.gitconfig.local with your [user] name/email"
echo "  - open tmux and press <prefix> + I to install tmux plugins (if not already installed)"
echo "Machine-local shell extras go in ~/.zshrc.local."
