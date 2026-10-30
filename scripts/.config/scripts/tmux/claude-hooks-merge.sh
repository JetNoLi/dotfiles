#!/usr/bin/env bash
# claude-hooks-merge.sh [settings.json] — add wb's hook entries to Claude
# Code's settings if they're missing, leaving every other setting as it is
# (KTD7). Stowing settings.json instead would replace the whole file. An
# entry is matched on its command string.
set -euo pipefail

settings="${1:-$HOME/.claude/settings.json}"
dir='~/.config/scripts/tmux'

mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"

jq --arg dir "$dir" '
  def add($event; $cmd):
    if any(.hooks[$event][]?.hooks[]?; .command == $cmd) then .
    else .hooks[$event] += [{hooks: [{type: "command", command: $cmd}]}] end;
  .hooks //= {}
  | add("UserPromptSubmit"; $dir + "/claude-notify-hook.sh start")
  | add("Notification"; $dir + "/claude-notify-hook.sh needs-input")
  | add("Stop"; $dir + "/claude-notify-hook.sh done")
  | add("SessionStart"; $dir + "/claude-pickup-hook.sh")
' "$settings" > "$settings.tmp.$$"
mv "$settings.tmp.$$" "$settings"
