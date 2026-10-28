#!/usr/bin/env bash
# wb done, through the real CLI.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
wb() { "$BASH" "$WB" "$@"; }
make_repo "$T/code/dotfiles"
REPO="$T/code/dotfiles"

# --- a background task: stop first, then remove --------------------------------------------
wb new --bg dotfiles bg-task >/dev/null 2>&1
out="$(WB_TEST_WT="$REPO/.worktrees/bg-task" wb done --close dotfiles--bg-task 2>&1)"; code=$?
assert_eq "wb done on a --bg task succeeds" 0 "$code"
assert "it stops the background session" '^stop 86e34592$' "$(cat "$T/claude.log")"
assert "it stops it before removing the worktree" 'worktree present at stop' "$(cat "$T/claude.log")"
assert_eq "the worktree is gone" "" "$(git -C "$REPO" worktree list | grep bg-task)"
assert_eq "the task is done" done "$(wb_task_get "$TASKS_DIR/dotfiles--bg-task.md" status)"
assert_eq "closed is stamped" "$(date +%F)" "$(wb_task_get "$TASKS_DIR/dotfiles--bg-task.md" closed)"
assert_eq "--close ends the session" "" "$(tmux list-sessions -F '#S' 2>/dev/null | grep bg-task)"

# --- no decision-buffer script, session kept without --close -----------------------------------
wb new dotfiles plain >/dev/null 2>&1
out="$(wb done dotfiles--plain 2>&1)"; code=$?
assert_eq "wb done with no decision-buffer script completes" 0 "$code"
assert_eq "and removes the worktree" "" "$(git -C "$REPO" worktree list | grep plain)"
assert "without --close the session stays" 'dotfiles--plain' "$(tmux list-sessions -F '#S')"

# --- uncommitted work ----------------------------------------------------------------------------
wb new dotfiles dirty >/dev/null 2>&1
echo change > "$REPO/.worktrees/dirty/new-file"
out="$(wb done dotfiles--dirty 2>&1)"; code=$?
assert_eq "a dirty worktree is refused" 1 "$code"
assert "the refusal lists the change" 'new-file' "$out"
assert "the worktree is kept" 'dirty' "$(git -C "$REPO" worktree list)"
assert_eq "the task stays open" doing "$(wb_task_get "$TASKS_DIR/dotfiles--dirty.md" status)"

# --- family nudge ------------------------------------------------------------------------------
wb new dotfiles parent >/dev/null 2>&1
wb new --parent dotfiles--parent dotfiles child >/dev/null 2>&1
out="$(wb done dotfiles--child 2>&1)"
assert "closing the last open child names the parent to close" 'close it with: wb done dotfiles--parent' "$out"

finish
