#!/usr/bin/env bash
# Claude Code SessionStart hook → when a wb task's session starts in a clean
# context, put its latest /handoff checkpoint in front of Claude (KTD5).
#
# Wired from ~/.claude/settings.json by install.sh:
#   SessionStart -> claude-pickup-hook.sh
#
#   source=clear    acts whenever the task has a checkpoint (Jet ran /clear)
#   source=startup  acts only when a pick-up marker exists for the task: the
#                   auto-clear restart and /handoff new write one
#   anything else   nothing; compaction and resume keep the conversation
#
# The instructions travel in the injected text because a skill's body isn't
# loaded after a clear. A marker holding "start" (from /handoff new) says to
# begin the next step; otherwise Claude states the checkpoint and waits.
# Always exits 0, printing nothing when there is nothing to pick up.
set -uo pipefail

WB_PICKUP_BUDGET="${WB_PICKUP_BUDGET:-8500}"   # characters of checkpoint; the field caps at 10,000

input=""
[ -t 0 ] || input="$(cat)"
src="$(jq -r '.source // empty' <<< "$input" 2>/dev/null)"
sid="$(jq -r '.session_id // empty' <<< "$input" 2>/dev/null)"
case "$src" in clear|startup) ;; *) exit 0 ;; esac

# wb needs bash 5; sourced under an older one it exits before anything is
# logged, so the missed pick-up is logged here.
if [ "${BASH_VERSINFO[0]:-0}" -lt 5 ]; then
  st="${WB_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/wb}"; mkdir -p "$st"
  printf '%s - no pick-up: the SessionStart hook needs bash 5, found %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "${BASH_VERSION:-?}" >> "$st/handoff.log"
  exit 0
fi

# shellcheck source=/dev/null
source "$(dirname "$0")/wb" 2>/dev/null || exit 0
set +e +u

file="$(wb_task_for_session "$sid" 2>/dev/null)" || exit 0
stem="$(wb_task_stem "$file")"
marker="$(wb_pickup_marker "$stem")"
mode=wait
if [ -f "$marker" ]; then
  [ "$(cat "$marker" 2>/dev/null)" = start ] && mode=start
  rm -f "$marker"
elif [ "$src" = startup ]; then
  exit 0
fi

body="$(wb_pickup_text "$file")" || exit 0
when="$(sed -n '1s/^### \(.*\) — checkpoint$/\1/p' <<< "$body")"
age=""
if then_s="$(wb_date_to_epoch "$when" 2>/dev/null)" && [ -n "$then_s" ]; then
  mins=$(( ($(date +%s) - then_s) / 60 ))
  if   [ "$mins" -lt 60 ];   then age="$mins minutes ago"
  elif [ "$mins" -lt 2880 ]; then age="$(( mins / 60 )) hours ago"
  else                            age="$(( mins / 1440 )) days ago"
  fi
fi
if [ "${#body}" -gt "$WB_PICKUP_BUDGET" ]; then
  body="${body:0:$WB_PICKUP_BUDGET}"$'\n\n'"[Trimmed. The full entry is in $file under ## Handoffs; read it before acting.]"
fi

if [ "$mode" = start ]; then
  steps="- This task was just handed to you with /handoff new. Start on the Next step now, without asking. Say in one line what you are picking up.
- If the entries after the checkpoint change the plan, say so and follow them."
else
  steps="- In your first reply, say: \"Picked up the checkpoint from $when${age:+ ($age)}. Next: <the Next action>.\" Then ask Jet whether to go ahead.
- If entries are listed after the checkpoint, name each one and say the recorded plan may be stale because of them.
- If the checkpoint lists open decisions, or open /decide surfaces are listed, say how many and where they wait. Once Jet says go, collect the answers as the /decide skill describes.
- Then wait. Don't start the Next step until Jet confirms or redirects."
fi

ctx="wb pick-up: this session works on the task $stem ($file). It started in a clean context after a /handoff checkpoint.

$steps

$body"

jq -n --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
exit 0
