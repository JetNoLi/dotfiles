#!/usr/bin/env bash
# Ordering, the display string, the snapshot, and the needs-you cursor, fed
# with rows in rows.sh's 13-field shape.
set -uo pipefail
source "$(dirname "$0")/helpers.sh"
source "$WB"
set +e
export FZF_COLUMNS=200 WB_PICKER_NOW=1000000

# row <repo> <label> <session> <visit> [status] [kind] [nest] [target]
row() {
  local icon
  case "${5:-idle}" in
    needs-input) icon='! needs you'; r=0 ;; done) icon='+ finished'; r=1 ;; waiting) icon='o done'; r=1 ;;
    working) icon='* working'; r=2 ;; none) icon='- no agent'; r=3 ;; *) icon='- idle'; r=3 ;;
  esac
  printf '%s\t%s\t[main]\t%s\t%s\t%s\t%s\t/ref/%s\t%s\t1\t\t%s\t%s\n' \
    "$1" "$2" "$r" "$icon" "${8:-}" "$3" "$3" "${6:-task}" "${7:-}" "$4"
}
blocks() { local r; for r in "$@"; do printf '%s\n%s\n' "$_WB_BLOCK_MARK" "$r"; done; }
plain() { sed $'s/\033\\[[0-9;]*m//g' | cut -f1; }
order() { wb_order_blocks | cut -f2 | xargs; }

A1="$(row alpha a-old s1 100)"; A2="$(row alpha a-new s2 300)"; B1="$(row beta b-mid s3 200)"

# --- grouping and order -------------------------------------------------------------
assert_eq "repos order by their newest visit, rows by visit inside a repo" \
  "a-new a-old b-mid" "$(blocks "$A1" "$B1" "$A2" | order)"
out="$(blocks "$A1" "$B1" "$A2" | wb_order_blocks | wb_format_for_display | plain)"
assert "the repo name prints on a group's first row" '^alpha +a-new' "$(sed -n 1p <<< "$out")"
assert "and is blank on the rows after it" '^ +a-old' "$(sed -n 2p <<< "$out")"
out="$(blocks "$A1" "$B1" "$A2" | wb_order_blocks | WB_PICKER_MODE=search wb_format_for_display | plain)"
assert "in search mode every row names its repo" '^alpha +a-old' "$(sed -n 2p <<< "$out")"

# --- the pinned family ------------------------------------------------------------------
out="$(blocks "$A1" "$B1" "$A2" | WB_PICKER_SESSION=s3 wb_order_blocks | WB_PICKER_SESSION=s3 wb_format_for_display)"
assert "the current session's block comes first, tagged (here)" '^beta +b-mid \(here\)' "$(plain <<< "$out" | sed -n 1p)"
assert_eq "a separator row follows the pinned family" sep "$(sed -n 2p <<< "$out" | cut -f10)"
assert_eq "the separator row has no session for keys to act on" "" "$(sed -n 2p <<< "$out" | cut -f8)"

# --- status changes colour, never position ------------------------------------------------
before="$(blocks "$A1" "$A2" | order)"
A1w="$(row alpha a-old s1 100 needs-input)"
assert_eq "a status change doesn't move a row" "$before" "$(blocks "$A1w" "$A2" | order)"
assert "the needs-you row turns bold magenta" $'\033\\[1;35ma-old' "$(blocks "$A1w" "$A2" | wb_order_blocks | wb_format_for_display | cut -f1)"
colour_of() { blocks "$(row alpha a-old s1 100 "$1")" | wb_order_blocks | wb_format_for_display | cut -f1; }
assert "a Claude at its prompt (done) is green" $'\033\\[32ma-old' "$(colour_of waiting)"
assert "a finished long turn is cyan, though it shares done's rank" $'\033\\[36ma-old' "$(colour_of done)"
assert "a working row is yellow" $'\033\\[33ma-old' "$(colour_of working)"
assert "a session with no agent is grey" $'\033\\[90ma-old' "$(colour_of none)"

# --- multi-byte names -----------------------------------------------------------------------
long="$(printf 'caf\xc3\xa9 %.0s' {1..40})"
out="$(blocks "$(row alpha "$long" s1 100)" "$(row alpha short s2 100)" | wb_order_blocks | wb_format_for_display | plain)"
w1="$(sed -n 1p <<< "$out" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')"
w2="$(sed -n 2p <<< "$out" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')"
assert_eq "a multi-byte name pads to the same width as an ASCII one" "$w2" "$w1"
assert "a long name ends in an ASCII ellipsis" '\.\.\. +main' "$(sed -n 1p <<< "$out")"
assert_eq "no broken UTF-8 sequence is left" 0 "$(sed -n 1p <<< "$out" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; echo $?)"

# --- the cursor and u ----------------------------------------------------------------------------
mode="$T/mode"; view="$T/view"; echo normal > "$mode"; echo live > "$view"
N1="$(row alpha n1 s1 500 needs-input)"; N2="$(row beta n2 s2 400 needs-input)"
HERE="$(row gamma mine s9 600 needs-input)"; P="$(row alpha plain s4 450)"
blocks "$HERE" "$N1" "$P" "$N2" | WB_PICKER_SESSION=s9 wb_order_blocks \
  | WB_PICKER_SESSION=s9 wb_format_for_display "$view.snap" > /dev/null
assert_eq "the header count leaves out the own row" $'count\t2' "$(head -n1 "$view.snap")"
first="$(_initial_pos "$mode" "$view")"
assert_eq "the cursor opens on the first row that needs Jet (after here + separator)" "pos(3)" "$first"
assert_eq "u moves to the next one" "pos(5)" "$(FZF_POS=3 _next_needs "$mode" "$view")"
assert_eq "u wraps to the first" "pos(3)" "$(FZF_POS=5 _next_needs "$mode" "$view")"
assert_eq "the own row never counts for u" "pos(3)" "$(FZF_POS=0 _next_needs "$mode" "$view")"

finish
