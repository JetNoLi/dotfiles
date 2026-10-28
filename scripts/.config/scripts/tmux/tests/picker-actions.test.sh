#!/usr/bin/env bash
# The picker's ctrl-x action, run the way fzf's become() runs it: stdout is
# what fzf hands back as the selection, so nothing may leak there.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
wb() { "$BASH" "$WB" "$@"; }
make_repo "$T/code/dotfiles"
REPO="$T/code/dotfiles"

# ctrl_x <keys> <args...> — run _ctrl-x outside tmux with <keys> typed in;
# stdout goes to $T/out, stderr to $T/err.
ctrl_x() { local keys="$1"; shift; printf '%s' "$keys" | env -u TMUX "$BASH" "$WB" _ctrl-x "$@" > "$T/out" 2> "$T/err"; }

# --- a dormant task row --------------------------------------------------------------------
wb new dotfiles parked >/dev/null 2>&1
REF="$TASKS_DIR/dotfiles--parked.md"
tmux kill-session -t =dotfiles--parked
ctrl_x n task "" "" "$REF"
assert "the dormant prompt says the worktree is removed" 'Removes the worktree' "$(cat "$T/err")"
assert "N leaves the worktree" 'parked' "$(git -C "$REPO" worktree list)"

echo change > "$REPO/.worktrees/parked/new-file"
ctrl_x yk task "" "" "$REF"; code=$?
assert_eq "a refused wb done still exits cleanly" 0 "$code"
assert_eq "nothing reaches fzf's selection" "" "$(cat "$T/out")"
assert "the refusal is shown" 'uncommitted changes' "$(cat "$T/err")"
assert "and held until a key is pressed" 'done failed.*press any key' "$(cat "$T/err")"
assert "the worktree is kept" 'parked' "$(git -C "$REPO" worktree list)"

rm "$REPO/.worktrees/parked/new-file"
ctrl_x y task "" "" "$REF"; code=$?
assert_eq "a clean ctrl-x succeeds" 0 "$code"
assert_eq "its output does not reach fzf's selection" "" "$(cat "$T/out")"
assert "wb done's summary goes to the terminal" 'task done' "$(cat "$T/err")"
assert_eq "the worktree is gone" "" "$(git -C "$REPO" worktree list | grep parked)"

finish
