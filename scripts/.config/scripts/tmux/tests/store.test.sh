#!/usr/bin/env bash
# store.sh — seeding, frontmatter, handoffs, families.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

export TASKS_DIR="$T/fresh-store"   # doesn't exist yet

# --- seeding --------------------------------------------------------------------
file="$(wb_task_seed proj fix-thing .worktrees/fix-thing /code/proj)"
assert_eq "seeding names the record <repo>--<slug>.md" "$TASKS_DIR/proj--fix-thing.md" "$file"
assert "seeding an empty store creates the template" 'status:' "$(cat "$TASKS_DIR/TEMPLATE.md" 2>/dev/null)"
assert_eq "a new record is doing" doing "$(wb_task_get "$file" status)"
assert_eq "a new record carries repo_path" /code/proj "$(wb_task_get "$file" repo_path)"
assert_eq "a new record carries the worktree" .worktrees/fix-thing "$(wb_task_get "$file" worktree)"
assert_eq "a new record's title comes from the slug" "fix thing" "$(wb_task_title "$file")"

echo "edited by hand" >> "$file"
before="$(cat "$file")"
again="$(wb_task_seed proj fix-thing .worktrees/other /elsewhere)"
assert_eq "seeding an existing slug returns the same record" "$file" "$again"
assert_eq "seeding an existing slug leaves it unchanged" "$before" "$(cat "$file")"

wb_task_set "$file" status planned
wb_task_seed proj fix-thing .worktrees/fix-thing /code/proj >/dev/null
assert_eq "re-seeding a planned task moves it back to doing" doing "$(wb_task_get "$file" status)"

# --- frontmatter writes ---------------------------------------------------------------
before_body="$(sed -n '/^# /,$p' "$file")"
wb_task_set "$file" branch new-branch
assert_eq "setting a field changes it" new-branch "$(wb_task_get "$file" branch)"
assert_eq "other fields are unchanged" /code/proj "$(wb_task_get "$file" repo_path)"
assert_eq "the body is unchanged" "$before_body" "$(sed -n '/^# /,$p' "$file")"
wb_task_set "$file" parent proj--other
assert "the inline comment on a set line is kept" '^parent: proj--other +# optional' "$(grep '^parent:' "$file")"
wb_task_set "$file" brand_new value
assert_eq "an absent key is inserted in the frontmatter" value "$(wb_task_get "$file" brand_new)"
wb_task_set "$file" branch 'a\nstatus: pwned'
assert_eq "a literal \\n in a value can't inject a line" 1 "$(grep -c '^status:' "$file")"

# --- handoffs ------------------------------------------------------------------------
wb_task_append_handoff "$file" "wb down" "Parked."
assert "a handoff lands under Handoffs, before Decisions" \
  '## Handoffs.*wb down \(auto\).*Parked\..*## Decisions' "$(tr '\n' ' ' < "$file")"

# --- typed entries (KTD6) -------------------------------------------------------------
wb() { "$BASH" "$WB" "$@"; }
export TASKS_DIR="$T/tasks"
e="$TASKS_DIR/proj--entries.md"
printf -- '---\nstatus: doing\nrepo: proj\n---\n# Entries\n\n## Plan\n\n## Handoffs\n\n### 2026-10-01 09:00 — wb resume (auto)\n\nResumed.\n\n## Decisions\n\n## Done\n' > "$e"
printf 'Done: a\nNext: b\n' | wb checkpoint --task proj--entries >/dev/null
assert "a checkpoint lands at the end of Handoffs as ### <date> — checkpoint" \
  'Resumed\. ### [0-9-]+ [0-9:]+ — checkpoint Done: a Next: b ## Decisions' "$(tr '\n' ' ' < "$e" | tr -s ' ')"

printf -- '---\nstatus: doing\n---\n# Bare\n\n## Plan\n\n## Decisions\n\n## Done\n' > "$TASKS_DIR/proj--bare.md"
echo 'Next: c' | wb checkpoint --task proj--bare >/dev/null
assert "a task without Handoffs gets the section before Decisions" \
  '## Plan ## Handoffs ### .* — checkpoint Next: c ## Decisions' "$(tr '\n' ' ' < "$TASKS_DIR/proj--bare.md" | tr -s ' ')"

printf 'Intro\n## Sneaky\n### Also\nend\n' | wb checkpoint --task proj--bare >/dev/null
assert_eq "a ## line in a body is demoted" 1 "$(grep -c '^#### Sneaky$' "$TASKS_DIR/proj--bare.md")"
assert_eq "so it opens no section of its own" 0 "$(grep -c '^## Sneaky$' "$TASKS_DIR/proj--bare.md")"
assert_eq "and a ### line in a body is demoted too" 1 "$(grep -c '^#### Also$' "$TASKS_DIR/proj--bare.md")"

p="$TASKS_DIR/proj--pick.md"
printf -- '---\nstatus: doing\n---\n# Pick\n\n## Handoffs\n\n### 2026-10-01 09:00 — checkpoint\n\nOld one.\n\n### 2026-10-02 14:02 — checkpoint\n\nNext: X\n\n### 2026-10-02 15:10 — wb down (auto)\n\nParked.\n\n### 2026-10-02 16:00 — from proj--other\n\nHanded over.\n\n## Decisions\n' > "$p"
out="$(wb pickup --task proj--pick)"
assert "pickup starts at the latest checkpoint" '^### 2026-10-02 14:02 — checkpoint' "$out"
assert_eq "pickup leaves out earlier checkpoints" 0 "$(grep -c 'Old one' <<< "$out")"
assert "pickup lists the auto entry and the incoming handoff after it" \
  'Next: X == Since this checkpoint == ### 2026-10-02 15:10 — wb down \(auto\) Parked\. ### 2026-10-02 16:00 — from proj--other Handed over\.' \
  "$(tr '\n' ' ' <<< "$out" | tr -s ' ')"
out="$(wb pickup --task proj--entries)"; code=$?
assert_eq "pickup with only a checkpoint has no gap list" 0 "$(grep -c 'Since this' <<< "$out")"
printf -- '---\nstatus: doing\n---\n# None\n\n## Handoffs\n\n### 2026-10-01 09:00 — wb down (auto)\n\nParked.\n' > "$TASKS_DIR/proj--none.md"
out="$(wb pickup --task proj--none 2>&1)"; code=$?
assert_eq "pickup on a task with no checkpoint fails" 1 "$code"
assert_eq "and prints nothing" "" "$out"

echo 'Use A.' | wb decision "Which approach" --task proj--pick
echo 'Use B, after all.' | wb decision "Which approach" --task proj--pick
echo 'Yes.' | wb decision "Ship it" --task proj--pick
assert_eq "a decision with an existing title replaces it" 1 "$(grep -c '^### Which approach$' "$p")"
assert "the replacement holds the new answer, then the next decision" \
  '## Decisions ### Which approach Use B, after all\. ### Ship it Yes\.$' "$(tr '\n' ' ' < "$p" | tr -s ' ' | sed 's/ $//')"
assert_eq "the old answer is gone" 0 "$(grep -c 'Use A' "$p")"

printf 'From elsewhere\n' | wb handoff-to proj--pick --task proj--bare >/dev/null
assert "handoff-to writes a from <stem> entry into the target" '### [0-9-]+ [0-9:]+ — from proj--bare' "$(cat "$p")"
out="$(echo x | wb handoff-to proj--missing 2>&1)"; code=$?
assert_eq "handoff-to a missing task fails" 1 "$code"
assert_eq "without creating its file" no "$([ -e "$TASKS_DIR/proj--missing.md" ] && echo yes || echo no)"

# --- locking (KTD1) -----------------------------------------------------------------------
c="$TASKS_DIR/proj--race.md"
printf -- '---\nstatus: doing\n---\n# Race\n\n## Handoffs\n\n## Decisions\n' > "$c"
for i in 1 2 3; do (echo "writer $i" | wb checkpoint --task proj--race >/dev/null) & done
wait
assert_eq "three concurrent checkpoints all land" 3 "$(grep -c '^writer [123]$' "$c")"

sleep 30 & holder=$!
mkdir -p "$WB_STATE_DIR/locks/proj--race.md.lock"; echo "$holder" > "$WB_STATE_DIR/locks/proj--race.md.lock/pid"
before="$(cat "$c")"
out="$(echo late | WB_LOCK_WAIT=1 wb checkpoint --task proj--race 2>&1)"; code=$?
assert_eq "a held lock makes checkpoint exit 75" 75 "$code"
assert_eq "and leaves the file unchanged" "$before" "$(cat "$c")"
kill "$holder" 2>/dev/null; wait "$holder" 2>/dev/null

sleep 1 & holder=$!
echo "$holder" > "$WB_STATE_DIR/locks/proj--race.md.lock/pid"
start=$SECONDS
echo "Renamed race" | wb _rename "" bg "$c" >/dev/null 2>&1
assert "a picker rename waits for a held lock" '^[1-9]' "$(( SECONDS - start ))"
assert_eq "then renames the task" "Renamed race" "$(wb_task_title "$c")"
wait "$holder" 2>/dev/null

# --- task-for-session (KTD14) -----------------------------------------------------------
tmux new-session -d -s proj--pick "sleep 300"
tmux set-option -t "=proj--pick:" @task "$p" >/dev/null
PANE="$(tmux list-panes -t "=proj--pick:" -F '#{pane_id}')"
assert_eq "a pane in a session with @task maps to that task" "$p" "$(TMUX_PANE="$PANE" wb task-for-session)"
fake_bg 424242 idle sid-bg job1 /code/proj
jq '.name = "proj--entries"' "$CLAUDE_SESSIONS_DIR/424242.json" > "$T/r.json" && mv "$T/r.json" "$CLAUDE_SESSIONS_DIR/424242.json"
assert_eq "with no pane, a session id whose registry name is a task stem maps to it" \
  "$e" "$(TMUX_PANE= wb task-for-session --session-id sid-bg)"
assert_eq "inside Claude's own commands, \$CLAUDE_PID finds the same session" \
  "$e" "$(CLAUDE_PID=424242 wb task-for-session)"
out="$(TMUX_PANE= wb task-for-session --session-id nobody 2>/dev/null)"; code=$?
assert_eq "an unknown session id prints nothing" "" "$out"
assert_eq "and fails" 1 "$code"
out="$(echo x | TMUX_PANE= wb checkpoint --session-id nobody 2>&1)"; code=$?
assert "outside a wb task, checkpoint refuses and says there is no task" 'no task' "$out"
rm -f "$CLAUDE_SESSIONS_DIR/424242.json"

# --- repo_path fallback ----------------------------------------------------------------
make_repo "$T/code/legacy"
printf -- '---\nstatus: doing\nrepo: legacy\nworktree: .worktrees/x\n---\n# Old\n' > "$TASKS_DIR/legacy--x.md"
assert_eq "a record without repo_path resolves its repo by name" "$T/code/legacy" "$(wb_task_repo_path "$TASKS_DIR/legacy--x.md")"

# --- families -------------------------------------------------------------------------
mk() { printf -- '---\nstatus: doing\nrepo: proj\nparent: %s\n---\n# %s\n' "$2" "$1" > "$TASKS_DIR/$1.md"; }
mk proj--root ""
mk proj--child proj--root
mk proj--grandchild proj--child
assert_eq "a family tree lists the root, then descendants depth-first" \
  "proj--root proj--child proj--grandchild" "$(wb_family_tree proj--root | xargs)"
mk proj--loop-a proj--loop-b
mk proj--loop-b proj--loop-a
out="$(wb_family_tree proj--loop-a | sort | xargs)"
assert_eq "a family with a cycle stops at the repeated stem" "proj--loop-a proj--loop-b" "$out"

# --- transcript directories ---------------------------------------------------------
# Claude Code turns every non-alphanumeric in the cwd into "-"; the expected
# names are written out rather than derived.
assert_eq "/ and . become -" "$CLAUDE_PROJECTS_DIR/-Users-me-dotfiles--worktrees-fix" \
  "$(wb_transcript_dir /Users/me/dotfiles/.worktrees/fix)"
assert_eq "_ and spaces become - too" "$CLAUDE_PROJECTS_DIR/-Users-me-Desktop-My-Repo--worktrees-fix-login" \
  "$(wb_transcript_dir "/Users/me/Desktop/My Repo/.worktrees/fix_login")"

finish
