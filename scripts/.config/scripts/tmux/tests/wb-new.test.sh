#!/usr/bin/env bash
# wb new, through the real CLI.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
fake_claude_bin
wb() { "$BASH" "$WB" "$@"; }

make_repo "$T/code/dotfiles"
REPO="$T/code/dotfiles"

out="$(wb new dotfiles fix-thing 2>&1)"; code=$?
assert_eq "wb new succeeds" 0 "$code"
assert_eq "it creates the worktree on a new branch" fix-thing "$(git -C "$REPO/.worktrees/fix-thing" branch --show-current 2>/dev/null)"
assert_eq "it creates the session with nvim, agent and shell windows" "nvim agent shell" \
  "$(tmux list-windows -t =dotfiles--fix-thing: -F '#{window_name}' 2>/dev/null | xargs)"
task="$TASKS_DIR/dotfiles--fix-thing.md"
assert_eq "it writes the task with repo_path" "$REPO" "$(wb_task_get "$task" repo_path)"
assert_eq "the session's @task points at the record" "$task" "$(tmux show -t =dotfiles--fix-thing: -v @task)"
assert "it switches to the session" 'dotfiles--fix-thing' "$(cat "$T/focus.log")"
assert_eq "no agent is started or typed for a fresh task" 0 \
  "$(tmux capture-pane -p -t =dotfiles--fix-thing:agent | grep -v '^$' | grep -c claude)"

# --- repo from the shell's git root, even inside a worktree ------------------------------
out="$(cd "$REPO/.worktrees/fix-thing" && wb new other-thing 2>&1)"
assert_eq "with only a slug, the repo is the git root's (a worktree's main repo)" \
  "$(cd "$REPO" && pwd -P)" "$(wb_task_get "$TASKS_DIR/dotfiles--other-thing.md" repo_path)"
assert "and the worktree lands in the main repo" 'other-thing' "$(ls "$REPO/.worktrees")"

# --- ambiguous names --------------------------------------------------------------------
make_repo "$T/code/a/dup"; make_repo "$T/code/b/dup"
out="$(wb new dup thing 2>&1)"; code=$?
assert_eq "an ambiguous repo name fails" 1 "$code"
assert "it names the first path" "$T/code/a/dup" "$out"
assert "it names the second path" "$T/code/b/dup" "$out"
assert_eq "it creates no task" "" "$(ls "$TASKS_DIR" | grep dup)"
assert_eq "it creates no session" "" "$(tmux list-sessions -F '#S' | grep dup)"
assert_eq "it creates no worktree" "" "$(ls "$T/code/a/dup/.worktrees" "$T/code/b/dup/.worktrees" 2>/dev/null)"

# --- two writers racing on one slug --------------------------------------------------------
wb new dotfiles race >/dev/null 2>&1 & wb new dotfiles race >/dev/null 2>&1 & wait
assert_eq "racing on one slug makes one worktree" 1 "$(git -C "$REPO" worktree list | grep -c '/race ')"
assert_eq "and one intact task record" 1 "$(grep -c '^status: doing' "$TASKS_DIR/dotfiles--race.md")"
assert_eq "with its frontmatter closed" 2 "$(grep -c '^---$' "$TASKS_DIR/dotfiles--race.md")"

# --- --bg (AE4) --------------------------------------------------------------------------
: > "$T/focus.log"
out="$(wb new --bg dotfiles bg-thing 2>&1)"; code=$?
assert_eq "wb new --bg succeeds" 0 "$code"
assert "it starts claude --bg named after the session" '^--bg -n dotfiles--bg-thing$' "$(cat "$T/claude.log")"
assert "the record keeps the full session UUID as @primary" \
  '^86e34592-cdb9-4da2-bf55-6db85f3bc22e@[0-9T:Z-]+@primary$' "$(wb_task_get "$TASKS_DIR/dotfiles--bg-thing.md" claude_sessions)"
assert_eq "nothing is typed into the agent window" 0 "$(tmux capture-pane -p -t =dotfiles--bg-thing:agent | grep -c claude)"
assert_eq "it doesn't switch away from where you are" "" "$(cat "$T/focus.log")"
assert "the session shows as a bg row nested under its task" $'^bg\t86e34592\tc1$' \
  "$(collect_combined_rows | cut -f9,11,12)"

# --- /handoff new: a seeded background task (R10, KTD12) ------------------------------------
: > "$T/claude.log"; rm -f "$CLAUDE_SESSIONS_DIR"/515151.json
out="$(printf 'Done: split out\nNext: write the parser\n' | wb new --bg --handoff --parent dotfiles--fix-thing dotfiles seeded 2>&1)"; code=$?
assert_eq "wb new --bg --handoff succeeds" 0 "$code"
seeded="$TASKS_DIR/dotfiles--seeded.md"
assert "the new task is seeded with the checkpoint" '— checkpoint.*Next: write the parser' "$(tr '\n' ' ' < "$seeded")"
assert_eq "with a start marker for its first startup" start "$(cat "$WB_STATE_DIR/pickup/dotfiles--seeded" 2>/dev/null)"
assert "the background agent gets the pick-up prompt" '^--bg -n dotfiles--seeded Pick up this task from its /handoff checkpoint\.$' "$(cat "$T/claude.log")"
assert "and is still recorded as @primary" '@primary' "$(wb_task_get "$seeded" claude_sessions)"
assert_eq "its parent is the sending task" dotfiles--fix-thing "$(wb_task_get "$seeded" parent)"

: > "$T/claude.log"; rm -f "$CLAUDE_SESSIONS_DIR"/515151.json
wb new --bg dotfiles plain-bg >/dev/null 2>&1
assert_eq "wb new --bg without --handoff starts the agent with no prompt" "--bg -n dotfiles--plain-bg" "$(cat "$T/claude.log")"
assert_eq "and writes no pick-up marker" no "$([ -e "$WB_STATE_DIR/pickup/dotfiles--plain-bg" ] && echo yes || echo no)"

out="$(echo 'Next: x' | wb new --bg --handoff dotfiles seeded 2>&1)"; code=$?
assert_eq "--handoff onto an existing task refuses" 1 "$code"
assert "pointing at /handoff <task> instead" 'already exists' "$out"

finish
