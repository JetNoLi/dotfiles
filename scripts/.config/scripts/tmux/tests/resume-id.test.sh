#!/usr/bin/env bash
# wb_resume_id ranking (KTD11).
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

wt="$T/code/proj/.worktrees/fix"
dir="$(wb_transcript_dir "$wt")"
mkdir -p "$dir"
task="$T/tasks/proj--fix.md"
printf -- '---\nstatus: doing\nclaude_sessions:\n---\n# Fix\n' > "$task"

turn() { printf '{"parentUuid":"x","type":"user","timestamp":"%s"}\n' "$1"; }
bookkeeping() { printf '{"type":"frame-link","timestamp":"%s"}\n' "$1"; }

# old-active: real activity last; mtime older. new-mtime: bookkeeping newer.
{ turn 2026-10-25T10:00:00.000Z; turn 2026-10-25T12:00:00.000Z; } > "$dir/old-active.jsonl"
{ turn 2026-10-25T09:00:00.000Z; bookkeeping 2026-10-25T13:00:00.000Z; } > "$dir/new-mtime.jsonl"
touch_epoch 1793100000 "$dir/old-active.jsonl"
touch_epoch 1793100000 "$dir/new-mtime.jsonl"
assert_eq "with mtimes tied, the newest activity line wins" old-active "$(wb_resume_id "$task" "$wt")"
touch_epoch 1793190000 "$dir/new-mtime.jsonl"
assert_eq "the newest activity line wins over a newer mtime" old-active "$(wb_resume_id "$task" "$wt")"

wb_task_set "$task" claude_sessions "new-mtime@2026-10-25T09:00:00Z@primary,old-active@2026-10-25T12:00:00Z"
assert_eq "@primary wins when its transcript exists" new-mtime "$(wb_resume_id "$task" "$wt")"
wb_task_set "$task" claude_sessions "gone@2026-10-25T09:00:00Z@primary"
assert_eq "a @primary with no transcript falls back to ranking" old-active "$(wb_resume_id "$task" "$wt")"

rm "$dir"/*.jsonl
: > "$dir/a.jsonl"; : > "$dir/b.jsonl"
touch_epoch 1793100000 "$dir/a.jsonl"
touch_epoch 1793190000 "$dir/b.jsonl"
assert_eq "with no activity lines, mtime decides" b "$(wb_resume_id "$task" "$wt")"

assert_eq "no transcripts gives no id" "" "$(wb_resume_id "$task" "$T/code/none")"

snap="$(wb_sessions_snapshot "$wt" b)"
assert_eq "the snapshot lists oldest first and marks the primary" \
  "a@2026-10-27T11:20:00Z,b@2026-10-28T12:20:00Z@primary" "$snap"

finish
