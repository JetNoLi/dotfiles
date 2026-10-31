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
mkdir -p "$WB_STATE_DIR/needs-you"; echo "page https://claude.ai/artifact/x" > "$WB_STATE_DIR/needs-you/dotfiles--bg-task"
out="$(WB_TEST_WT="$REPO/.worktrees/bg-task" wb done --close dotfiles--bg-task 2>&1)"; code=$?
assert_eq "wb done on a --bg task succeeds" 0 "$code"
assert_eq "it stops showing the task as needing Jet" no "$([ -e "$WB_STATE_DIR/needs-you/dotfiles--bg-task" ] && echo yes || echo no)"
assert "it stops the background session" '^stop 86e34592$' "$(cat "$T/claude.log")"
assert "it stops it before removing the worktree" 'worktree present at stop' "$(cat "$T/claude.log")"
assert_eq "the worktree is gone" "" "$(git -C "$REPO" worktree list | grep bg-task)"
assert_eq "the task is done" done "$(wb_task_get "$TASKS_DIR/dotfiles--bg-task.md" status)"
assert_eq "closed is stamped" "$(date +%F)" "$(wb_task_get "$TASKS_DIR/dotfiles--bg-task.md" closed)"
assert_eq "--close ends the session" "" "$(tmux list-sessions -F '#S' 2>/dev/null | grep bg-task)"

# --- an agent writing while it is stopped ------------------------------------------------------
wb new --bg dotfiles late-write >/dev/null 2>&1
out="$(WB_TEST_STOP_WRITES="$REPO/.worktrees/late-write/late-file" wb done dotfiles--late-write 2>&1)"; code=$?
assert_eq "work written while the agent stops is refused" 1 "$code"
assert "the refusal lists the late file" 'late-file' "$out"
assert "the worktree is kept" 'late-write' "$(git -C "$REPO" worktree list)"
rm -f "$REPO/.worktrees/late-write/late-file"; wb done dotfiles--late-write >/dev/null 2>&1

# --- a background agent that won't stop ----------------------------------------------------------
wb new --bg dotfiles stuck >/dev/null 2>&1
sessions="$(wb_task_get "$TASKS_DIR/dotfiles--stuck.md" claude_sessions)"
out="$(WB_TEST_STOP_FAILS=1 wb done dotfiles--stuck 2>&1)"; code=$?
assert_eq "a failed stop aborts wb done" 1 "$code"
assert "it says the agent is still running" 'still running' "$out"
assert "the worktree is kept" 'stuck' "$(git -C "$REPO" worktree list)"
assert_eq "the task stays open" doing "$(wb_task_get "$TASKS_DIR/dotfiles--stuck.md" status)"
assert_eq "the record keeps the session id for a retry" "$sessions" "$(wb_task_get "$TASKS_DIR/dotfiles--stuck.md" claude_sessions)"

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

# --- a dirty background task: refused before its agent is stopped -------------------------------
wb new --bg dotfiles dirty-bg >/dev/null 2>&1
echo change > "$REPO/.worktrees/dirty-bg/new-file"
: > "$T/claude.log"
out="$(wb done dotfiles--dirty-bg 2>&1)"; code=$?
assert_eq "a dirty --bg worktree is refused" 1 "$code"
assert_eq "its agent is left running" "" "$(grep '^stop' "$T/claude.log")"
rm "$REPO/.worktrees/dirty-bg/new-file"; wb done dotfiles--dirty-bg >/dev/null 2>&1

# --- a repo with a submodule -------------------------------------------------------------------
make_repo "$T/code/libsub"
git -C "$REPO" -c protocol.file.allow=always submodule add -q "$T/code/libsub" libsub >/dev/null 2>&1
git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm "add submodule"
wb new dotfiles with-sub >/dev/null 2>&1
git -C "$REPO/.worktrees/with-sub" -c protocol.file.allow=always submodule update -q --init >/dev/null 2>&1
out="$(wb done dotfiles--with-sub 2>&1)"; code=$?
assert_eq "a clean worktree with a submodule is removed" 0 "$code"
assert_eq "and is gone" "" "$(git -C "$REPO" worktree list | grep with-sub)"

# --- family nudge ------------------------------------------------------------------------------
wb new dotfiles parent >/dev/null 2>&1
wb new --parent dotfiles--parent dotfiles child >/dev/null 2>&1
out="$(wb done dotfiles--child 2>&1)"
assert "closing the last open child names the parent to close" 'close it with: wb done dotfiles--parent' "$out"

finish
