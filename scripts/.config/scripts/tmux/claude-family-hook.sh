#!/usr/bin/env bash
# Claude Code SessionStart and UserPromptSubmit hook → keep a family
# session's view of its family current (KTD4).
#
# Wired from ~/.claude/settings.json by install.sh:
#   SessionStart      -> claude-family-hook.sh   (every source)
#   UserPromptSubmit  -> claude-family-hook.sh
#
# On SessionStart it prints `wb family` as added context, opening with a
# reminder to follow /family (KTD6). Before a prompt it prints the view
# again only when it changed since this session last saw it. The hash
# leaves out `Updated:` lines and the reading session's own status block,
# so routine status writes don't re-inject the view every turn. The seen
# hash lives in $WB_STATE_DIR/family-seen/<session id>.
# Always exits 0, printing nothing for a task with no family, a done task,
# a session with no task, or bash older than 5.
set -uo pipefail

WB_FAMILY_BUDGET="${WB_FAMILY_BUDGET:-8500}"   # characters of view; the field caps at 10,000

input=""
[ -t 0 ] || input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<< "$input" 2>/dev/null)"
sid="$(jq -r '.session_id // empty' <<< "$input" 2>/dev/null)"
[ -n "$event" ] || { [ -n "$(jq -r '.source // empty' <<< "$input" 2>/dev/null)" ] && event=SessionStart; }
case "$event" in SessionStart|UserPromptSubmit) ;; *) exit 0 ;; esac

[ "${BASH_VERSINFO[0]:-0}" -ge 5 ] || exit 0

# shellcheck source=/dev/null
source "$(dirname "$0")/wb" 2>/dev/null || exit 0
set +e +u

file="$(wb_task_for_session "$sid" 2>/dev/null)" || exit 0
[ "$(wb_task_get "$file" status 2>/dev/null)" != "done" ] || exit 0
stem="$(wb_task_stem "$file")"
mapfile -t members < <(wb_family_members "$stem" 2>/dev/null)
[ "${#members[@]}" -ge 2 ] || exit 0
view="$(wb_family_view view "${members[@]}")" || exit 0
[ -n "$view" ] || exit 0

# The hash skips Updated: lines and this task's own block in the Status
# part: from its "-- <stem> --" header to the next blank line.
hash="$(awk -v me="$stem" '
  /^== / { status = ($0 == "== Status ==") }
  status && ($0 == "-- " me " --" || $0 == "-- " me " (coordinator) --") { skip = 1; next }
  skip { if ($0 == "") skip = 0; else next }
  /^Updated:/ { next }
  { print }
' <<< "$view" | cksum | tr -d ' \t')"

seen_dir="$WB_STATE_DIR/family-seen"
seen="$seen_dir/${sid:-$stem}"
if [ "$event" = UserPromptSubmit ] && [ "$(cat "$seen" 2>/dev/null)" = "$hash" ]; then
  exit 0
fi
mkdir -p "$seen_dir" && printf '%s\n' "$hash" > "$seen"

if [ "${#view}" -gt "$WB_FAMILY_BUDGET" ]; then
  view="${view:0:$WB_FAMILY_BUDGET}"$'\n\n'"[Trimmed. Run \`wb family\` for the whole view.]"
fi
if [ "$event" = SessionStart ]; then
  lead="wb family: this session's task $stem is in a family. Follow the /family skill. The family view:"
else
  lead="wb family: the family view changed since this session last saw it. Follow the /family skill. The view now:"
fi

jq -n --arg ev "$event" --arg ctx "$lead"$'\n\n'"$view" \
  '{hookSpecificOutput: {hookEventName: $ev, additionalContext: $ctx}}'
exit 0
