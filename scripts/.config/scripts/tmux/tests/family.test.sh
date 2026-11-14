#!/usr/bin/env bash
# family.sh — the family view (U1) and its write verbs (U2): family
# decisions in the root's task file, a status block in each member's.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
wb() { "$BASH" "$WB" "$@"; }

# mk <stem> <parent> [status] — a task file with the template's sections.
mk() {
  printf -- '---\nstatus: %s\nrepo: proj\nparent: %s\n---\n# %s\n\n## Plan\n\n## Handoffs\n\n## Decisions\n\n## Done\n' \
    "${3:-doing}" "$2" "$1" > "$TASKS_DIR/$1.md"
}
f() { echo "$TASKS_DIR/$1.md"; }

mk proj--root ""
mk proj--hook proj--root
mk proj--picker proj--root
mk proj--deep proj--hook

# A root with two proposed and one in-force decision, written straight into
# the file as a coordinator's edits would leave it.
cat >> "$(f proj--root)" <<'EOF'

## Family decisions

### One family view
status: proposed
affects: [proj--hook, proj--picker]
discussed in: proj--root

Both need the same view.

### Hash the view
status: in-force
affects: [proj--hook]
discussed in: proj--root
confirmed: 2026-11-14, Jet: "yes"

### Count on the anchor row
status: proposed
affects: [proj--picker]
discussed in: proj--root
from: proj--picker / Anchor row count
EOF
printf '\n## Status\n\nPhase: building\nTouching: wb-lib/family.sh\nHolding: nothing\n' >> "$(f proj--hook)"
printf '\n## Status\n\nPhase: planning\nTouching: wb-lib/rows.sh\nHolding: the count, until "One family view"\n' >> "$(f proj--picker)"

# --- the view (U1) ------------------------------------------------------------------
view="$(wb family --task proj--hook)"
flat="$(tr '\n' ' ' <<< "$view" | tr -s ' ')"
assert "the view lists proposed decisions first, then in force, then status blocks" \
  'One family view.*Count on the anchor row.*In force.*Hash the view.*Status.*proj--hook.*Phase: building.*proj--picker.*Phase: planning' "$flat"
assert "a proposed decision shows what it affects and where it is discussed" \
  'One family view status: proposed affects: \[proj--hook, proj--picker\] discussed in: proj--root' "$flat"
assert_eq "two decisions wait on Jet" 2 "$(wb family --waiting --task proj--hook)"

assert_eq "the view is the same from the root" "$view" "$(wb family --task proj--root)"
assert_eq "and from a grandchild" "$view" "$(wb family --task proj--deep)"
assert "a member with no status block shows as empty" 'proj--deep -+ \(no status block\)' "$flat"

# A worker proposal no family decision cites is listed and counted (R11).
cat > "$T/body" <<'EOF'
status: proposed
affects: [proj--picker]

The hook should read the view, not the files.
EOF
wb decision "Hook reads the view" --task proj--hook < "$T/body"
flat="$(wb family --task proj--root | tr '\n' ' ' | tr -s ' ')"
assert "an untaken worker proposal is listed last" \
  'Status.*Not yet taken in.*proj--hook / Hook reads the view.*affects: \[proj--picker\]' "$flat"
assert_eq "and adds one to the count" 3 "$(wb family --waiting --task proj--root)"

# A worker proposal a family decision cites with from: is taken in.
cat > "$T/body" <<'EOF'
status: proposed
affects: [proj--picker]
from: proj--hook / Hook reads the view
EOF
wb family-decision "Hook reads the view" --task proj--root < "$T/body"
flat="$(wb family --task proj--root | tr '\n' ' ' | tr -s ' ')"
assert_eq "once a family decision cites it, it is no longer listed" "" "$(grep -o 'Not yet taken in' <<< "$flat")"
assert_eq "and the count is the family decision's alone" 3 "$(wb family --waiting --task proj--root)"

# A Decisions entry with no affects: line is single-task (AE2).
printf 'status: proposed\n\nOnly this task.\n' | wb decision "Local only" --task proj--picker
assert_eq "a single-task proposal never appears" "" "$(wb family --task proj--root | grep 'Local only')"

# A done member drops out of the view and the count.
mk proj--old proj--root done
printf '\n## Status\n\nPhase: reviewing\n' >> "$(f proj--old)"
printf 'status: proposed\naffects: [proj--hook]\n' | wb decision "Stale idea" --task proj--old
out="$(wb family --task proj--root)"
assert_eq "a done member's status block is not listed" "" "$(grep 'proj--old' <<< "$out")"
assert_eq "and its proposals aren't counted" 3 "$(wb family --waiting --task proj--root)"

# --- no family ---------------------------------------------------------------------------
mk proj--alone ""
out="$(wb family --task proj--alone 2>&1)"; code=$?
assert_eq "a task with no family prints nothing" "" "$out"
assert "and fails" '^[1-9]' "$code"

mk proj--loop-a proj--loop-b
mk proj--loop-b proj--loop-a
( "$BASH" "$WB" family --task proj--loop-a > "$T/loop.out" 2>&1; echo $? > "$T/loop.code" ) &
loop_pid=$!
if wait_until 5 test -s "$T/loop.code"; then
  assert_eq "a parent: cycle prints nothing" "" "$(cat "$T/loop.out")"
  assert "and fails rather than looping" '^[1-9]' "$(cat "$T/loop.code")"
else
  echo "FAIL - a parent: cycle loops"; fail=1; kill "$loop_pid" 2>/dev/null
fi

mk proj--bare-root ""
mk proj--bare-kid proj--bare-root
printf -- '---\nstatus: doing\nparent: proj--bare-root\n---\n# Kid\n' > "$(f proj--bare-kid)"
out="$(wb family --task proj--bare-kid)"; code=$?
assert_eq "a family with no decisions or status sections still prints" 0 "$code"
assert_eq "with nothing waiting" 0 "$(wb family --waiting --task proj--bare-kid)"

# --- family-decision (U2) ------------------------------------------------------------------
r="$(f proj--write-root)"
mk proj--write-root ""
mk proj--write-kid proj--write-root
before_plan="$(sed -n '/^## Plan/,/^## Handoffs/p' "$r")"
printf 'status: proposed\naffects: [proj--write-kid]\n' | wb family-decision "First call" --task proj--write-root
assert "a new family decision lands in a new section before Done" \
  '## Decisions ## Family decisions ### First call status: proposed .*## Done' "$(tr '\n' ' ' < "$r" | tr -s ' ')"
assert_eq "the other sections are unchanged" "$before_plan" "$(sed -n '/^## Plan/,/^## Handoffs/p' "$r")"

printf 'status: in-force\naffects: [proj--write-kid]\nconfirmed: 2026-11-14, Jet: "go"\n' \
  | wb family-decision "First call" --task proj--write-root
assert_eq "writing the same title again leaves one entry" 1 "$(grep -c '^### First call$' "$r")"
assert_eq "holding the new status" 1 "$(grep -c '^status: in-force$' "$r")"

out="$(printf 'status: proposed\n' | wb family-decision "From a worker" --task proj--write-kid 2>&1)"
assert "run from a worker, it warns that only the coordinator writes these" 'coordinator' "$out"
assert_eq "and still writes to the root's file" 1 "$(grep -c '^### From a worker$' "$r")"
assert_eq "not the worker's" 0 "$(grep -c 'From a worker' "$(f proj--write-kid)")"

for i in 1 2 3 4 5; do (printf 'status: proposed\n' | wb family-decision "Race $i" --task proj--write-root >/dev/null 2>&1) & done
wait
assert_eq "five concurrent family decisions all land" 5 "$(grep -c '^### Race [1-5]$' "$r")"

out="$(wb family-decision "Empty" --task proj--write-root < /dev/null 2>&1)"; code=$?
assert "an empty body is refused" '^[1-9]' "$code"

out="$(printf 'x\n' | wb family-decision "Lonely" --task proj--alone 2>&1)"; code=$?
assert "family-decision on a task with no family fails" '^[1-9]' "$code"
assert "saying why" 'family' "$out"

# --- status (U2) ---------------------------------------------------------------------------
k="$(f proj--write-kid)"
printf 'Phase: planning\nTouching: nothing yet\nHolding: nothing\n' | wb status --task proj--write-kid
assert "a status block lands after the title, before the first section" \
  '^# proj--write-kid ## Status Phase: planning Touching: nothing yet Holding: nothing Updated: [0-9-]+ [0-9:]+ ## Plan' \
  "$(sed -n '/^# /,$p' "$k" | tr '\n' ' ' | tr -s ' ')"
printf 'Phase: building\nTouching: family.sh\nHolding: nothing\nUpdated: stale\n' | wb status --task proj--write-kid
assert_eq "writing it again leaves one Status section" 1 "$(grep -c '^## Status$' "$k")"
assert_eq "holding the second body" 1 "$(grep -c '^Phase: building$' "$k")"
assert_eq "the first is gone" 0 "$(grep -c '^Phase: planning$' "$k")"
assert_eq "with one fresh Updated line" 1 "$(grep -c '^Updated: [0-9]' "$k")"
assert_eq "and none from the body" 0 "$(grep -c '^Updated: stale' "$k")"

out="$(wb status --task proj--write-kid < /dev/null 2>&1)"; code=$?
assert "an empty status body is refused" '^[1-9]' "$code"

# store.sh's decisions still behave after the section writer is shared.
d="$(f proj--write-root)"
printf 'one\n' | wb decision "Plain" --task proj--write-root
printf 'two\n' | wb decision "Plain" --task proj--write-root
assert_eq "wb decision still replaces by title" 1 "$(grep -c '^### Plain$' "$d")"
assert "in the Decisions section, not Family decisions" '## Decisions ### Plain two ## Family decisions' "$(tr '\n' ' ' < "$d" | tr -s ' ')"

finish
