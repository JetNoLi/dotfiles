#!/usr/bin/env bash
# claude-statusline.sh, Claude Code's statusLine; and claude-hooks-merge.sh
# wiring it in.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
set +e
SL="$(dirname "$WB")/claude-statusline.sh"
MERGE="$(dirname "$WB")/claude-hooks-merge.sh"

# sl <json> [env…] — the line with its colours stripped and padding trimmed
sl() {
  local json="$1"; shift
  printf '%s' "$json" | env "$@" "$BASH" "$SL" | sed -e $'s/\033\\[[0-9;]*m//g' -e 's/^ *//'
}

base='"model":{"display_name":"Opus 5.5"},"context_window":{"used_percentage":42.7}'

assert_eq "with only a model and context it shows those two" \
  "42% ctx · Opus 5.5" "$(sl "{$base}")"

assert_eq "a linked worktree and effort follow the model" \
  "42% ctx · ⎇ feat-x · Opus 5.5 · high" \
  "$(sl "{$base,\"workspace\":{\"git_worktree\":\"feat-x\"},\"effort\":{\"level\":\"high\"}}")"

make_repo "$T/code/proj"
assert_eq "in a main checkout the worktree is the repo's folder" \
  "42% ctx · ⎇ proj · Opus 5.5" "$(sl "{$base,\"workspace\":{\"current_dir\":\"$T/code/proj\"}}")"

mkdir -p "$T/plain"
assert_eq "outside git there is no worktree part" \
  "42% ctx · Opus 5.5" "$(sl "{$base,\"workspace\":{\"current_dir\":\"$T/plain\"}}")"

read -r p1 _ < <(fake_claude_pane proj--feat)
tmux set -t "=proj--feat:" @task "$TASKS_DIR/proj--feat.md"
assert_eq "in a wb pane the task comes from the session's @task" \
  "42% ctx · proj--feat · Opus 5.5" "$(sl "{$base,\"session_name\":\"other\"}" TMUX_PANE="$p1")"

read -r p2 _ < <(fake_claude_pane two)
tmux set -t "=two:" @wb_repo proj
tmux set -t "=two:" @wb_slug two
assert_eq "without @task it falls back to @wb_repo--@wb_slug" \
  "42% ctx · proj--two · Opus 5.5" "$(sl "{$base}" TMUX_PANE="$p2")"

assert_eq "with no pane (a background session) the session name stands in" \
  "42% ctx · proj--bg · Opus 5.5" "$(sl "{$base,\"session_name\":\"proj--bg\"}")"

now=$(date +%s)
limits="\"rate_limits\":{\"five_hour\":{\"used_percentage\":30.4,\"resets_at\":$((now + 4830))},\"seven_day\":{\"used_percentage\":88,\"resets_at\":$((now + 3*86400 + 4*3600 + 60))}}"
assert_eq "plan usage shows each window with its countdown" \
  "42% ctx · Opus 5.5 · 5h 30% ↻1h20m · wk 88% ↻3d4h" "$(sl "{$base,$limits}")"

assert_eq "a window without a reset time shows just its percentage" \
  "42% ctx · Opus 5.5 · wk 5%" "$(sl "{$base,\"rate_limits\":{\"seven_day\":{\"used_percentage\":5}}}")"

assert "weekly usage at 88% is coloured red" $'wk\033\\[0m \033\\[38;2;210;15;57m88%' \
  "$(printf '%s' "{$base,$limits}" | "$BASH" "$SL")"

out="$(printf '%s' "{$base}" | COLUMNS=40 "$BASH" "$SL" | sed $'s/\033\\[[0-9;]*m//g')"
assert_eq "it is right-aligned to the terminal width" 40 "${#out}"

assert_eq "under bash 3.2 it still prints the line" \
  "42% ctx · Opus 5.5" "$(printf '%s' "{$base}" | /bin/bash "$SL" | sed -e $'s/\033\\[[0-9;]*m//g' -e 's/^ *//')"

assert_eq "an empty payload still prints a line" "0% ctx · ?" "$(sl '')"

# claude-hooks-merge.sh
s="$T/settings.json"
echo '{"theme":"dark"}' > "$s"
"$BASH" "$MERGE" "$s"
assert_eq "the merge adds the statusLine" "command ~/.config/scripts/tmux/claude-statusline.sh" \
  "$(jq -r '.statusLine | "\(.type) \(.command)"' "$s")"
assert_eq "and keeps the other settings" dark "$(jq -r .theme "$s")"

echo '{"statusLine":{"type":"command","command":"my-own.sh"}}' > "$s"
"$BASH" "$MERGE" "$s"
assert_eq "a statusLine already set is left alone" my-own.sh "$(jq -r .statusLine.command "$s")"

printf '{"theme": "dark",\n' > "$s"; before="$(cat "$s")"
out="$("$BASH" "$MERGE" "$s" 2>&1)"; code=$?
assert_eq "settings that aren't valid JSON make the merge fail" 1 "$code"
assert "and it says so" "isn't valid JSON" "$out"
assert_eq "the file is left as it was" "$before" "$(cat "$s")"
assert_eq "and no temp file is left behind" "" "$(ls "$T" | grep 'settings.json.tmp')"

finish
