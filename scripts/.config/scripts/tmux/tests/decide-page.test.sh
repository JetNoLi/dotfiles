#!/usr/bin/env bash
# The /decide page's spec check, and its URL surviving a restart through wb pickup.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
wb() { "$BASH" "$WB" "$@"; }

cat > "$T/items.json" <<'JSON'
{"title": "Store format", "layout": "items", "items": [
  {"id": "fmt", "title": "Which format", "context": "Two choices.",
   "options": [{"id": "md", "label": "Markdown", "recommended": true}, {"id": "json", "label": "JSON"}],
   "blocks": [{"type": "code", "text": "ls ~/tasks"}, {"type": "table", "head": ["a"], "rows": [["1"]]}]}]}
JSON
cat > "$T/verdicts.json" <<'JSON'
{"title": "Review findings", "layout": "verdicts",
 "verdicts": [{"id": "fix", "label": "Fix"}, {"id": "skip", "label": "Skip"}],
 "items": [{"id": "f1", "title": "Unlocked write", "suggested": "fix"}, {"id": "f2", "title": "Typo"}]}
JSON
assert_eq "a per-item spec passes" ok "$(wb decide-spec-check "$T/items.json" 2>&1)"
assert_eq "a shared-verdict spec passes" ok "$(wb decide-spec-check "$T/verdicts.json" 2>&1)"

jq 'del(.items[0].id)' "$T/items.json" > "$T/noid.json"
out="$(wb decide-spec-check "$T/noid.json" 2>&1)"; code=$?
assert_eq "a spec with an item missing its id fails" 1 "$code"
assert "naming the item" 'an item has no id: Which format' "$out"
jq '.items += [.items[0]]' "$T/items.json" > "$T/dup.json"
assert "a repeated item id fails" 'item id fmt is used twice' "$(wb decide-spec-check "$T/dup.json" 2>&1)"
jq '.items[0].suggested = "maybe"' "$T/verdicts.json" > "$T/badsugg.json"
assert "a suggestion that isn't a verdict fails" "suggests maybe, which is not one of the verdicts" "$(wb decide-spec-check "$T/badsugg.json" 2>&1)"
echo '{nope' > "$T/bad.json"
assert "invalid JSON fails" "isn't valid JSON" "$(wb decide-spec-check "$T/bad.json" 2>&1)"

# --- AE5: the page survives a clear through the checkpoint ---------------------------------
f="$TASKS_DIR/proj--page.md"
printf -- '---\nstatus: doing\n---\n# Page\n\n## Handoffs\n\n## Decisions\n' > "$f"
printf 'Next: collect the page\nOpen decisions: 7 on https://claude.ai/artifact/abc (page)\n' | wb checkpoint --task proj--page >/dev/null
assert "AE5: pickup carries the page URL from the open-decisions line" 'https://claude.ai/artifact/abc' "$(wb pickup --task proj--page)"

finish
