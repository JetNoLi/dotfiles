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

# A nameless session leaves an empty field, which must not shift the cwd.
fake_bg 454545 idle noname-sid nonamejob "$T/code/other"
jq '.name = ""' "$CLAUDE_SESSIONS_DIR/454545.json" > "$T/nn" && mv "$T/nn" "$CLAUDE_SESSIONS_DIR/454545.json"
assert "a nameless bg session keeps its cwd as the row's ref" \
  $'^other\t[^\t]*\t\t\t'"$T/code/other"$'\tbg\tnonamejob\t$' "$(kind_rows bg | grep nonamejob)"
fake_bg 464646 idle wt-noname-sid wtnoname "$WT"
jq '.name = ""' "$CLAUDE_SESSIONS_DIR/464646.json" > "$T/nn" && mv "$T/nn" "$CLAUDE_SESSIONS_DIR/464646.json"
assert "a nameless bg session in a task's worktree counts as the task's" \
  $'^wtnoname\twt-noname-sid$' "$(_wb_task_bg_jobs "$task" | grep wtnoname)"
rm -f "$CLAUDE_SESSIONS_DIR/454545.json" "$CLAUDE_SESSIONS_DIR/464646.json"

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

# --- U6: a family's waiting count on its anchor row -------------------------------------
tmux kill-server 2>/dev/null
rm -f "$CLAUDE_SESSIONS_DIR"/*.json
: > "$T/ps-extra"
# fam <slug> <parent> [live] — a task in repo fam, with a live session unless "dormant".
fam() {
  local file; file="$(wb_task_seed fam "$1" ".worktrees/$1" "$T/code/fam" "$2")"
  [ "${3:-live}" = dormant ] || task_session "fam--$1" fam "$1" "$file"
  echo "$file"
}
decide() { printf '\n## Family decisions\n' >> "$1"; shift; local t; for t in "$@"; do printf '\n### %s\nstatus: proposed\naffects: [x]\ndiscussed in: y\n' "$t" >> "$TASKS_DIR/fam--a-root.md"; done; }
make_repo "$T/code/fam"
aroot="$(fam a-root "")"; achild="$(fam a-kid fam--a-root)"
decide "$aroot" "One view" "Count on the row"
broot="$(fam b-root "")"; fam b-kid fam--b-root >/dev/null
croot="$(fam c-root "" dormant)"; ckid1="$(fam c-kid1 fam--c-root)"; ckid2="$(fam c-kid2 fam--c-root)"
wb_task_set "$ckid2" created 2026-11-01; wb_task_set "$ckid1" created 2026-11-02
printf '\n## Decisions\n\n### Hook reads the view\nstatus: proposed\naffects: [fam--c-kid1]\n' >> "$ckid1"

frows() { collect_combined_rows | awk -F'\t' '{ print $2 "\t" $12 "\t" $14 }'; }
has_line() { assert_eq "$1" 1 "$(grep -cxF -- "$2" <<< "$3")"; }
out="$(frows)"
has_line "a root with 2 waiting carries the count on its row" $'a root\t\t2' "$out"
has_line "its child carries none" $'a kid\tc1\t' "$out"
has_line "a root with 0 waiting carries 0, which shows nothing" $'b root\t\t0' "$out"
has_line "AE4: with the root not live, the earliest-created child anchors and shows 1" $'c kid2\t\t1' "$out"
has_line "and its sibling carries none" $'c kid1\t1\t' "$out"

disp="$(collect_combined_rows | wb_format_for_display "$T/snap" | sed $'s/\033\\[[0-9;]*m//g')"
assert "the root's row shows \"2 to decide\"" 'a root \(2 to decide\)' "$(cut -f1 <<< "$disp")"
assert "the anchoring child shows \"1 to decide\"" 'c kid2 \(1 to decide\)' "$(cut -f1 <<< "$disp")"
assert_eq "no other row is tagged" 2 "$(cut -f1 <<< "$disp" | grep -c 'to decide')"
pos="$(grep -n $'\tc kid2\t' <<< "$disp" | cut -d: -f1)"
assert_eq "AE4: the anchoring child counts as needing Jet for u" 1 \
  "$(awk -F'\t' -v p="$pos" 'NR > 1 && $1 == p { print $3 }' "$T/snap")"
pos="$(grep -n $'\tb root\t' <<< "$disp" | cut -d: -f1)"
assert_eq "a root with 0 waiting doesn't" 0 "$(awk -F'\t' -v p="$pos" 'NR > 1 && $1 == p { print $3 }' "$T/snap")"
echo normal > "$T/mode"; echo live > "$T/view"; cp "$T/snap" "$T/view.snap"
aroot_pos="$(grep -n $'\ta root\t' <<< "$disp" | cut -d: -f1)"
ckid_pos="$(grep -n $'\tc kid2\t' <<< "$disp" | cut -d: -f1)"
first=$(( aroot_pos < ckid_pos ? aroot_pos : ckid_pos ))
assert_eq "u jumps to the first family with decisions waiting" "pos($first)" "$(FZF_POS=0 _next_needs "$T/mode" "$T/view")"

# Each family's files are read once per render, however many rows it has.
eval "_orig_$(declare -f wb_family_view)"
wb_family_view() { echo "$*" >> "$T/view-calls"; _orig_wb_family_view "$@"; }
: > "$T/view-calls"
collect_combined_rows > /dev/null
assert_eq "a render with three families reads each family's files once" 3 "$(grep -c . "$T/view-calls")"
assert_eq "three different families" 3 "$(awk '{ print $2 }' "$T/view-calls" | sort -u | grep -c .)"
unset -f wb_family_view; eval "$(declare -f _orig_wb_family_view | sed 's/^_orig_wb_family_view/wb_family_view/')"

finish
