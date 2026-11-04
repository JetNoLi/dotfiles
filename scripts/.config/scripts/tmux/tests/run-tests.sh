#!/usr/bin/env bash
# run-tests.sh — run every wb test file and print a summary.
# Usage: run-tests.sh [name-filter]
set -uo pipefail
cd "$(dirname "$0")"

passed=0; failed=()
for t in *.test.sh; do
  [[ "$t" == *"${1:-}"* ]] || continue
  echo "== $t"
  if "$BASH" "$t"; then
    passed=$(( passed + 1 ))
  else
    failed+=("$t")
  fi
done

echo
echo "$passed passed, ${#failed[@]} failed"
[ "${#failed[@]}" -eq 0 ] || { printf '  failed: %s\n' "${failed[@]}"; exit 1; }
