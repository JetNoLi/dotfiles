#!/usr/bin/env bash
# repos.sh resolver across roots (KTD5).
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e

make_repo "$T/home/dotfiles"
make_repo "$T/home/Desktop/Projects/app"
make_repo "$T/home/Desktop/Projects/group/sub/deep"
git -C "$T/home/Desktop/Projects/app" worktree add -q -b feature .worktrees/feature
export WB_REPO_ROOTS="$T/home/dotfiles:$T/home/Desktop"

assert_eq "a root that is itself a repo" "$T/home/dotfiles" "$(wb_repo_resolve dotfiles)"
assert_eq "a repo under Desktop/Projects" "$T/home/Desktop/Projects/app" "$(wb_repo_resolve app)"
assert_eq "a repo nested two levels below Projects" "$T/home/Desktop/Projects/group/sub/deep" "$(wb_repo_resolve deep)"

out="$(wb_repo_resolve feature)"; code=$?
assert_eq "a worktree inside a repo isn't listed as a repo" 1 "$code"

out="$(wb_repo_resolve nope 2>&1)"; code=$?
assert_eq "an unknown name prints nothing" "" "$out"
assert_eq "an unknown name returns 1" 1 "$code"

make_repo "$T/home/Desktop/Other/app"
out="$(wb_repo_resolve app 2>&1)"; code=$?
assert_eq "an ambiguous name returns 2" 2 "$code"
assert "the error lists the first path" "$T/home/Desktop/Other/app" "$out"
assert "the error lists the second path" "$T/home/Desktop/Projects/app" "$out"

finish
