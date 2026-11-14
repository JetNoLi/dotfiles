#!/usr/bin/env bash
# The transcript-only context card (KTD8), through `wb _card` as the preview
# runs it.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
card() { "$BASH" "$WB" _card "$@"; }
plain() { sed $'s/\033\\[[0-9;]*m//g'; }

read -r pane cpid < <(fake_claude_pane agent)
target="agent:$(tmux display -p -t "$pane" '#{window_index}.#{pane_index}')"
registry "$cpid" idle "$pane" interactive "" card-sid
tr="$CLAUDE_PROJECTS_DIR/-code-proj/card-sid.jsonl"
mkdir -p "${tr%/*}"

prompt() { jq -nc --arg t "$1" --arg ts "$2" '{type: "user", origin: {kind: "human"}, timestamp: $ts, message: {content: $t}}'; }
reply()  { jq -nc --arg t "$1" '{type: "assistant", message: {content: [{type: "thinking", thinking: "x"}, {type: "text", text: $t}]}}'; }
tool()   { jq -nc '{type: "user", message: {content: [{type: "tool_result", content: "ls output"}]}}'; }
recap()  { jq -nc --arg t "$1" --arg ts "$2" '{type: "system", subtype: "away_summary", timestamp: $ts, content: $t}'; }

{
  prompt $'Fix the login bug\nit fails on Safari' 2026-10-28T09:00:00.000Z
  reply "Looking." ; tool
  prompt $'Now add a test\nfor the Safari case' 2026-10-28T10:00:00.000Z
  tool
  reply $'Added the test.\n\n## Needs you\n- Keep the old fallback, or drop it?'
  recap "Fixed login on Safari and added a test." 2026-10-28T10:05:00.000Z
} > "$tr"

out="$(card "$target" "" "" "" 2>"$T/err")"; code=$?
assert_eq "a live session's card succeeds" 0 "$code"
assert "it leads with the registry state, idle shown as done" '^done ' "$(plain <<< "$out" | head -n1)"
assert "it shows the recap" 'Recap.*Fixed login on Safari and added a test\.' "$(plain <<< "$out" | tr '\n' ' ')"
assert "it shows the last prompt" 'You asked.*Now add a test for the Safari case' "$(plain <<< "$out" | tr '\n' ' ')"
assert "and the first line of the one before" 'before that: Fix the login bug' "$(plain <<< "$out")"
assert "it shows the start of the reply" 'Claude replied.*Added the test\.' "$(plain <<< "$out" | tr '\n' ' ')"
assert_eq "a tool result isn't taken for a prompt" 0 "$(plain <<< "$out" | grep -c 'ls output')"
assert "a Needs you section lists its items" 'Needs you.*Keep the old fallback, or drop it\?' "$(plain <<< "$out" | sed -n '/── Needs you/,$p' | tr '\n' ' ')"
assert_eq "with no reply log or status cache there are no artifact, decision or cost lines" 0 \
  "$(plain <<< "$out" | grep -cE 'Artifacts|Decisions|\$[0-9]|% ctx')"
assert_eq "and nothing on stderr" "" "$(cat "$T/err")"

prompt "One more thing" 2026-10-28T10:10:00.000Z >> "$tr"
out="$(card "$target" "" "" "" | plain)"
assert_eq "a turn started after the recap hides it" 0 "$(grep -c Recap <<< "$out")"
assert "the new prompt is the one shown" 'You asked.*One more thing' "$(tr '\n' ' ' <<< "$out")"

# --- the other registry states -----------------------------------------------------------
state_line() { registry "$cpid" "$1" "$pane" interactive "" card-sid; card "$target" "" "" "" | plain | head -n1; }
touch "$tr"
assert "a busy session with recent activity says busy" '^busy <1m' "$(state_line busy)"
touch_epoch $(( $(date +%s) - 900 )) "$tr"   # past WB_CARD_QUIET_AFTER (600s)
assert "busy with no activity for a while says quiet" '^quiet .*\(busy, no activity\)' "$(state_line busy)"
assert "waiting says it's waiting on you" '^waiting on you' "$(state_line waiting)"
assert_eq "a status it doesn't know says so" "state unknown" "$(state_line rebooting)"
registry "$cpid" idle "$pane" interactive "" card-sid

# --- no prompt yet / no Claude ---------------------------------------------------------
: > "$tr"
out="$(card "$target" "" "" "")"; code=$?
assert_eq "a session with no prompt yet exits 3, so the preview adds its own" 3 "$code"
assert "it still prints the state" '^done' "$(plain <<< "$out")"

tmux new-session -d -s plain "sleep 300"
out="$(card "plain:$(tmux display -p -t =plain: '#{window_index}.#{pane_index}')" "" "" "")"; code=$?
assert_eq "a pane with no Claude prints nothing" "" "$out"
assert "and exits non-zero" '^[1-9]' "$code"

# --- a background session's row ----------------------------------------------------------
fake_bg 424242 busy bg-sid bgjob /code/proj
{ prompt "Background job" 2026-10-28T10:00:00.000Z; reply "On it."; } > "$CLAUDE_PROJECTS_DIR/-code-proj/bg-sid.jsonl"
out="$(card "" bg bgjob "" | plain)"
assert "a bg row's card comes from its session" 'You asked.*Background job' "$(tr '\n' ' ' <<< "$out")"

# --- the Family section on a family's anchor row (U6) ---------------------------------------
mkt() { printf -- '---\nstatus: doing\nrepo: proj\nparent: %s\n---\n# %s\n\n## Decisions\n' "$2" "$1" > "$TASKS_DIR/$1.md"; }
mkt proj--root ""; mkt proj--kid proj--root
cat >> "$TASKS_DIR/proj--root.md" <<'EOF'

## Family decisions

### One family view
status: proposed
affects: [proj--kid]
discussed in: proj--root

### Hash the view
status: in-force
affects: [proj--kid]
discussed in: proj--root
EOF
printf '\n## Status\n\nPhase: building\nTouching: rows.sh\nHolding: nothing\n' >> "$TASKS_DIR/proj--kid.md"
fam() { "$BASH" "$WB" _family-card "$@" | plain; }
out="$(fam "$TASKS_DIR/proj--root.md" 1)"
assert "the root's preview opens with a Family section and its count" '^── Family · 1 to decide' "$(grep . <<< "$out" | head -n1)"
assert "it lists the open decision with what it affects and where it is discussed" \
  'Waiting on Jet: 1 == ### One family view status: proposed affects: \[proj--kid\] discussed in: proj--root .*In force' "$(tr '\n' ' ' <<< "$out" | tr -s ' ')"
assert "then each status block" 'Status == -- proj--root \(coordinator\) -- \(no status block\) -- proj--kid -- Phase: building' "$(tr '\n' ' ' <<< "$out" | tr -s ' ')"
assert_eq "it leaves out the view's title line" 0 "$(grep -c '^Family of' <<< "$out")"
assert "with nothing waiting the section has no count" '^── Family ─' "$(fam "$TASKS_DIR/proj--root.md" 0 | grep . | head -n1)"
assert_eq "a row that anchors no family gets no section" "" "$(fam "$TASKS_DIR/proj--kid.md" "")"
assert_eq "nor does a row with no task" "" "$(fam /nowhere 1)"

finish
