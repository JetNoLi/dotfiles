#!/usr/bin/env bash
# claude-family-hook.sh: what a family session is shown at start and before
# a prompt (U5).
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
wb() { "$BASH" "$WB" "$@"; }

HOOK="$(dirname "$WB")/claude-family-hook.sh"
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty'; }
# fire <event> [session_id] [pane] — run the hook as Claude Code would.
fire() {
  local src=""; [ "$1" = SessionStart ] && src=',"source":"startup"'
  printf '{"hook_event_name":"%s","session_id":"%s"%s}' "$1" "${2:-sid-hook}" "$src" \
    | TMUX_PANE="${3-$P}" "$HOOK"
}
mk() {
  printf -- '---\nstatus: %s\nrepo: proj\nparent: %s\n---\n# %s\n\n## Plan\n\n## Handoffs\n\n## Decisions\n\n## Done\n' \
    "${3:-doing}" "$2" "$1" > "$TASKS_DIR/$1.md"
}
f() { echo "$TASKS_DIR/$1.md"; }
pane_for() {
  tmux new-session -d -s "$1" "sleep 300"
  tmux set-option -t "=$1:" @task "$(f "$1")" >/dev/null
  tmux list-panes -t "=$1:" -F '#{pane_id}'
}

mk proj--root ""
mk proj--hook proj--root
mk proj--picker proj--root
mk proj--solo ""
P="$(pane_for proj--hook)"
PICKER="$(pane_for proj--picker)"

printf 'status: proposed\naffects: [proj--hook]\ndiscussed in: proj--root\n\nHash it.\n' \
  | wb family-decision "Hash the view" --task proj--root

out="$(fire SessionStart | ctx)"
assert "SessionStart gives the /family reminder" 'Follow the /family skill' "$out"
assert "and the family view" 'Family of proj--root.*Hash the view' "$(tr '\n' ' ' <<< "$out")"
assert_eq "the event name is echoed back" SessionStart "$(fire SessionStart | jq -r .hookSpecificOutput.hookEventName)"
assert_eq "the seen hash is stored under the session id" yes "$([ -s "$WB_STATE_DIR/family-seen/sid-hook" ] && echo yes || echo no)"

assert_eq "a prompt right after start prints nothing" "" "$(fire UserPromptSubmit)"
assert_eq "and the next one prints nothing" "" "$(fire UserPromptSubmit)"

printf 'status: in-force\naffects: [proj--hook]\ndiscussed in: proj--root\nconfirmed: 2026-11-14, Jet: "yes"\n\nHash it.\n' \
  | wb family-decision "Hash the view" --task proj--root
out="$(fire UserPromptSubmit)"
assert_eq "after a decision comes into force, the next prompt gets the view" UserPromptSubmit "$(jq -r .hookSpecificOutput.hookEventName <<< "$out")"
assert "with the decision under In force" '== In force ==.*Hash the view' "$(ctx <<< "$out" | tr '\n' ' ')"
assert_eq "and the prompt after that prints nothing" "" "$(fire UserPromptSubmit)"

printf 'Phase: building\nTouching: hook.sh\nHolding: nothing\n' | wb status --task proj--hook
assert_eq "this session's own status write doesn't re-print the view" "" "$(fire UserPromptSubmit)"
printf 'Phase: planning\nTouching: rows.sh\nHolding: nothing\n' | wb status --task proj--picker
fire UserPromptSubmit >/dev/null
sed -i.bak 's/^Updated: .*/Updated: 2001-01-01 00:00/' "$(f proj--picker)" && rm -f "$(f proj--picker).bak"
assert_eq "a sibling's status change that only moves Updated: prints nothing" "" "$(fire UserPromptSubmit)"
printf 'Phase: building\nTouching: rows.sh\nHolding: nothing\n' | wb status --task proj--picker
assert "a sibling's real status change prints the view" 'Phase: building.*rows\.sh' "$(fire UserPromptSubmit | ctx | tr '\n' ' ')"

out="$(fire UserPromptSubmit other-sid "$PICKER" | ctx)"
assert "a different session has its own seen hash" 'family view changed' "$out"

assert "every SessionStart source prints the view, even unchanged" 'Family of proj--root' "$(fire SessionStart | ctx)"

big="$(head -c 12000 /dev/zero | tr '\0' 'x')"
printf 'status: proposed\naffects: [proj--hook]\ndiscussed in: proj--root\n\n%s\n' "$big" \
  | wb family-decision "A long one" --task proj--root
out="$(fire SessionStart | ctx)"
assert "a long view is trimmed under the 10,000-character cap" '^[0-9]{4}$' "${#out}"
assert "with a pointer to wb family" 'Trimmed\. Run `wb family`' "$out"

# --- silent cases -----------------------------------------------------------------------
SOLO="$(pane_for proj--solo)"
out="$(fire SessionStart sid-solo "$SOLO"; echo "exit=$?")"
assert_eq "a task with no family exits 0 silently" exit=0 "$out"
out="$(fire UserPromptSubmit nobody ""; echo "exit=$?")"
assert_eq "a session with no task exits 0 silently" exit=0 "$out"
sed -i.bak 's/^status: doing/status: done/' "$(f proj--hook)" && rm -f "$(f proj--hook).bak"
out="$(fire SessionStart; echo "exit=$?")"
assert_eq "a done task's session exits 0 silently" exit=0 "$out"
out="$(echo '{"hook_event_name":"Stop","session_id":"x"}' | "$HOOK"; echo "exit=$?")"
assert_eq "another event exits 0 silently" exit=0 "$out"

if [ -x /bin/bash ] && [ "$(/bin/bash -c 'echo ${BASH_VERSINFO[0]}')" -lt 5 ]; then
  out="$(echo '{"hook_event_name":"SessionStart","session_id":"x"}' | TMUX_PANE="$PICKER" /bin/bash "$HOOK"; echo "exit=$?")"
  assert_eq "on bash 3.2 the family hook prints nothing and exits 0" exit=0 "$out"
fi

finish
