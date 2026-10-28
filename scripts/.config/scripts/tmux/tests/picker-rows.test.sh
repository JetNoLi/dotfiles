#!/usr/bin/env bash
# rows.sh against a real (private) tmux server: background rows, their
# nesting and dedupe, keys on a bg row, and the DORMANT tab.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
export FZF_COLUMNS=200

make_repo "$T/code/dotfiles"
make_repo "$T/code/other"
WT="$T/code/dotfiles/.worktrees/fix-thing"
mkdir -p "$WT"
SID=86e34592-cdb9-4da2-bf55-6db85f3bc22e
task="$(wb_task_seed dotfiles fix-thing .worktrees/fix-thing "$T/code/dotfiles")"
wb_task_set "$task" claude_sessions "$SID@2026-10-28T11:26:45Z@primary"

# task_session <name> <repo> <slug> <task-file> — a wb task session.
task_session() {
  tmux new-session -d -s "$1" -c "$T" "sleep 300"
  tmux set -t "=$1:" @wb_repo "$2"
  tmux set -t "=$1:" @wb_slug "$3"
  tmux set -t "=$1:" @task "$4"
}
rows() { collect_combined_rows | cut -f1,2,6-9,11,12; }   # repo label target session ref kind slug nest
kind_rows() { rows | awk -F'\t' -v k="$1" '$6 == k'; }

task_session dotfiles--fix-thing dotfiles fix-thing "$task"
fake_bg 424242 busy "$SID" 86e34592 "$WT"

# --- AE4: a background session nests under its task -------------------------------
out="$(rows)"
assert "AE4: the bg row follows its task's session row, nested as a child" \
  $'^dotfiles\tfix thing\t\tdotfiles--fix-thing\t[^\t]*\ttask\t\t\n[^\t]*\tfix thing\t\t\t[^\t]*\tbg\t86e34592\tc1$' "$out"
assert "the (bg) tag follows the name" 'fix thing \(bg\)' "$(collect_combined_rows | wb_format_for_display | cut -f1)"
assert "the bg row is coloured as working" $'\033\\[33m[^\t]*fix thing \\(bg\\)' "$(collect_combined_rows | wb_format_for_display | cut -f1)"

# The same session attached in a pane shows once, as the pane.
read -r pane _ < <(fake_claude_pane attached "claude attach 86e34592")
assert_eq "an attached bg session has no bg row" "" "$(kind_rows bg)"
assert "it shows as its pane's session instead" $'^attached\t' "$(rows | grep '^attached')"
tmux kill-session -t =attached

# Matching by cwd when no task names the session id.
wb_task_set "$task" claude_sessions ""
assert "a bg session matches its task by worktree cwd" $'\tbg\t86e34592\tc1$' "$(kind_rows bg)"

# --- a bg session with no task -----------------------------------------------------
fake_bg 434343 idle other-sid otherjob "$T/code/other"
out="$(kind_rows bg | grep otherjob)"
assert "a bg session matching no task is its own row in its cwd's repo group" \
  $'^other\tn-434343\t\t\t'"$T/code/other"$'\tbg\totherjob\t$' "$out"

# --- AE5: a session outside tmux that isn't in the background ------------------------
registry "$$" idle "" interactive "" desk-sid "" "$T/code/other"
assert_eq "AE5: an interactive session with no pane renders no row" "" "$(rows | grep -e n-$$ -e desk-sid)"

# --- keys on a bg row ------------------------------------------------------------------
out="$(_break_out "" bg < /dev/null 2>&1)"
assert "b on a bg row says there's no pane to break out" 'no pane to break out' "$out"
assert_eq "b on a bg row makes no session" 0 "$(tmux list-sessions | grep -vc -e '^dotfiles--fix-thing:')"
printf 'Renamed task\n' | _rename "" bg "$task" >/dev/null 2>&1
assert_eq "r on a bg row renames its task" "Renamed task" "$(wb_task_title "$task")"

# --- DORMANT ---------------------------------------------------------------------------
mkdir -p "$(wb_transcript_dir "$WT")"
echo '{"parentUuid":"x","timestamp":"2026-10-25T10:00:00.000Z"}' > "$(wb_transcript_dir "$WT")/t1.jsonl"
tmux kill-session -t =dotfiles--fix-thing
assert_eq "a task whose worktree has a live bg session isn't dormant" "" "$(collect_dormant_rows normal)"
rm "$CLAUDE_SESSIONS_DIR/424242.json"
touch_epoch "$(( $(date +%s) - 3 * 86400 ))" "$(wb_transcript_dir "$WT")/t1.jsonl"
out="$(collect_dormant_rows normal)"
assert "a doing task with a transcript and no live session is dormant" $'^dotfiles\tRenamed task\t' "$out"
assert "the dormant row shows the transcript's age" $'\t~ doing 3d\t' "$out"

finish
