#!/usr/bin/env bash
# claude-hooks-merge.sh [settings.json] — add wb's notify-hook entries to
# Claude Code's settings if they're missing, leaving every other setting as
# it is (KTD7). Stowing settings.json instead would replace the whole file.
set -euo pipefail

settings="${1:-$HOME/.claude/settings.json}"
hook='~/.config/scripts/tmux/claude-notify-hook.sh'

mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"

jq --arg hook "$hook" '
  def add($event; $arg):
    ($hook + " " + $arg) as $cmd
    | if any(.hooks[$event][]?.hooks[]?; .command == $cmd) then .
      else .hooks[$event] += [{hooks: [{type: "command", command: $cmd}]}] end;
  .hooks //= {}
  | add("UserPromptSubmit"; "start")
  | add("Notification"; "needs-input")
  | add("Stop"; "done")
' "$settings" > "$settings.tmp.$$"
mv "$settings.tmp.$$" "$settings"
