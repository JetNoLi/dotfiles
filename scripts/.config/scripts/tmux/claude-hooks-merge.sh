#!/usr/bin/env bash
# claude-hooks-merge.sh [settings.json] — add wb's hook entries, and its
# statusLine when none is set, to Claude Code's settings, leaving every
# other setting as it is (KTD7). Stowing settings.json instead would replace
# the whole file. An entry is matched on its command string. A file that
# isn't valid JSON is left alone and the merge fails.
set -euo pipefail

settings="${1:-$HOME/.claude/settings.json}"
# shellcheck disable=SC2088 # kept literal: Claude Code expands it in settings.json
dir='~/.config/scripts/tmux'

mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"
jq empty "$settings" 2>/dev/null \
  || { echo "claude-hooks-merge.sh: $settings isn't valid JSON, so wb's hooks weren't added; fix it and re-run" >&2; exit 1; }

jq --arg dir "$dir" '
  def add($event; $cmd):
    if any(.hooks[$event][]?.hooks[]?; .command == $cmd) then .
    else .hooks[$event] += [{hooks: [{type: "command", command: $cmd}]}] end;
  .hooks //= {}
  | add("UserPromptSubmit"; $dir + "/claude-notify-hook.sh start")
  | add("Notification"; $dir + "/claude-notify-hook.sh needs-input")
  | add("Stop"; $dir + "/claude-notify-hook.sh done")
  | add("Stop"; $dir + "/claude-autoclear.sh stop")
  | add("SessionStart"; $dir + "/claude-pickup-hook.sh")
  | .statusLine //= {type: "command", command: ($dir + "/claude-statusline.sh")}
' "$settings" > "$settings.tmp.$$"
mv "$settings.tmp.$$" "$settings"
