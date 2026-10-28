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
assert "it leads with the registry state" '^idle ' "$(plain <<< "$out" | head -n1)"
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

# --- no prompt yet / no Claude ---------------------------------------------------------
: > "$tr"
out="$(card "$target" "" "" "")"; code=$?
assert_eq "a session with no prompt yet exits 3, so the preview adds its own" 3 "$code"
assert "it still prints the state" '^idle' "$(plain <<< "$out")"

tmux new-session -d -s plain "sleep 300"
out="$(card "plain:$(tmux display -p -t =plain: '#{window_index}.#{pane_index}')" "" "" "")"; code=$?
assert_eq "a pane with no Claude prints nothing" "" "$out"
assert "and exits non-zero" '^[1-9]' "$code"

# --- a background session's row ----------------------------------------------------------
fake_bg 424242 busy bg-sid bgjob /code/proj
{ prompt "Background job" 2026-10-28T10:00:00.000Z; reply "On it."; } > "$CLAUDE_PROJECTS_DIR/-code-proj/bg-sid.jsonl"
out="$(card "" bg bgjob "" | plain)"
assert "a bg row's card comes from its session" 'You asked.*Background job' "$(tr '\n' ' ' <<< "$out")"

finish
