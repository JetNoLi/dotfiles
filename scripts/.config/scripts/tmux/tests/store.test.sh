#!/usr/bin/env bash
# store.sh — seeding, frontmatter, handoffs, families.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

export TASKS_DIR="$T/fresh-store"   # doesn't exist yet

# --- seeding --------------------------------------------------------------------
file="$(wb_task_seed proj fix-thing .worktrees/fix-thing /code/proj)"
assert_eq "seeding names the record <repo>--<slug>.md" "$TASKS_DIR/proj--fix-thing.md" "$file"
assert "seeding an empty store creates the template" 'status:' "$(cat "$TASKS_DIR/TEMPLATE.md" 2>/dev/null)"
assert_eq "a new record is doing" doing "$(wb_task_get "$file" status)"
assert_eq "a new record carries repo_path" /code/proj "$(wb_task_get "$file" repo_path)"
assert_eq "a new record carries the worktree" .worktrees/fix-thing "$(wb_task_get "$file" worktree)"
assert_eq "a new record's title comes from the slug" "fix thing" "$(wb_task_title "$file")"

echo "edited by hand" >> "$file"
before="$(cat "$file")"
again="$(wb_task_seed proj fix-thing .worktrees/other /elsewhere)"
assert_eq "seeding an existing slug returns the same record" "$file" "$again"
assert_eq "seeding an existing slug leaves it unchanged" "$before" "$(cat "$file")"

wb_task_set "$file" status planned
wb_task_seed proj fix-thing .worktrees/fix-thing /code/proj >/dev/null
assert_eq "re-seeding a planned task moves it back to doing" doing "$(wb_task_get "$file" status)"

# --- frontmatter writes ---------------------------------------------------------------
before_body="$(sed -n '/^# /,$p' "$file")"
wb_task_set "$file" branch new-branch
assert_eq "setting a field changes it" new-branch "$(wb_task_get "$file" branch)"
assert_eq "other fields are unchanged" /code/proj "$(wb_task_get "$file" repo_path)"
assert_eq "the body is unchanged" "$before_body" "$(sed -n '/^# /,$p' "$file")"
wb_task_set "$file" parent proj--other
assert "the inline comment on a set line is kept" '^parent: proj--other +# optional' "$(grep '^parent:' "$file")"
wb_task_set "$file" brand_new value
assert_eq "an absent key is inserted in the frontmatter" value "$(wb_task_get "$file" brand_new)"
wb_task_set "$file" branch 'a\nstatus: pwned'
assert_eq "a literal \\n in a value can't inject a line" 1 "$(grep -c '^status:' "$file")"

# --- handoffs ------------------------------------------------------------------------
wb_task_append_handoff "$file" "wb down" "Parked."
assert "a handoff lands under Handoffs, before Decisions" \
  '## Handoffs.*wb down \(auto\).*Parked\..*## Decisions' "$(tr '\n' ' ' < "$file")"

# --- repo_path fallback ----------------------------------------------------------------
make_repo "$T/code/legacy"
printf -- '---\nstatus: doing\nrepo: legacy\nworktree: .worktrees/x\n---\n# Old\n' > "$TASKS_DIR/legacy--x.md"
assert_eq "a record without repo_path resolves its repo by name" "$T/code/legacy" "$(wb_task_repo_path "$TASKS_DIR/legacy--x.md")"

# --- families -------------------------------------------------------------------------
mk() { printf -- '---\nstatus: doing\nrepo: proj\nparent: %s\n---\n# %s\n' "$2" "$1" > "$TASKS_DIR/$1.md"; }
mk proj--root ""
mk proj--child proj--root
mk proj--grandchild proj--child
assert_eq "a family tree lists the root, then descendants depth-first" \
  "proj--root proj--child proj--grandchild" "$(wb_family_tree proj--root | xargs)"
mk proj--loop-a proj--loop-b
mk proj--loop-b proj--loop-a
out="$(wb_family_tree proj--loop-a | sort | xargs)"
assert_eq "a family with a cycle stops at the repeated stem" "proj--loop-a proj--loop-b" "$out"

finish
