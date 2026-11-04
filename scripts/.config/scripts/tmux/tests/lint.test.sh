#!/usr/bin/env bash
# shellcheck over wb and its Claude hooks, at warning level. Skipped (and
# passing) where shellcheck isn't installed: `brew install shellcheck`.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
set +e
dir="$(dirname "$WB")"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "skip - shellcheck isn't installed"
  finish
fi
out="$(cd "$dir" && shellcheck -x -s bash -S warning wb wb-lib/*.sh claude-*.sh 2>&1)"; code=$?
assert_eq "shellcheck finds no warnings in wb and its hooks" 0 "$code"
[ "$code" = 0 ] || printf '%s\n' "$out" | head -40

finish
