#!/usr/bin/env bash
# tmux.conf and install.sh wiring for wb: the real tmux.conf loads into a
# throwaway server (HOME pointed at the test dir, so no plugin runs), and
# install.sh runs the hooks merge after stowing.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
set +e
ROOT="$(cd "$(dirname "$WB")/../../../.." && pwd)"
CONF="$ROOT/tmux/.config/tmux/tmux.conf"
CSOCK="wb-wiring-$$"
ctmux() { HOME="$T" "$REAL_TMUX" -L "$CSOCK" "$@"; }
trap 'ctmux kill-server 2>/dev/null; cleanup' EXIT

out="$(ctmux -f "$CONF" new-session -d -s w "sleep 60" 2>&1)"; code=$?
assert_eq "the real tmux.conf loads" 0 "$code"
assert "prefix+a opens the wb picker" 'new-window .*\.config/scripts/tmux/wb' "$(ctmux list-keys -T prefix a)"
assert "status-left shows claude-status.sh's count" 'claude-status\.sh' "$(ctmux show -gv status-left)"
assert_eq "extended keys are on, so Shift+Enter reaches Claude" on "$(ctmux show -sv extended-keys)"
assert "hyperlinks pass through to the terminal" '\*:hyperlinks' "$(ctmux show -sv terminal-features)"

INSTALL="$ROOT/install.sh"
assert "install.sh stows the scripts and claude packages" '^stow .* scripts .*claude' "$(grep '^stow ' "$INSTALL")"
stow_line="$(grep -n '^stow ' "$INSTALL" | cut -d: -f1)"
merge_line="$(grep -n 'claude-hooks-merge.sh$' "$INSTALL" | cut -d: -f1)"
assert "install.sh runs the hooks merge" '^[0-9]+$' "$merge_line"
assert_eq "after stowing, so the hook scripts exist" yes "$([ "${merge_line:-0}" -gt "${stow_line:-0}" ] && echo yes || echo no)"

finish
