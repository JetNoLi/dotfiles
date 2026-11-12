# card.sh — the session context card in the picker preview (R2, KTD8):
# where a Claude session stands, read from the session registry and the
# conversation's own transcript. Sections, each left out when empty:
#   state      busy | waiting on you | idle | quiet <age> | state unknown
#   recap      Claude Code's latest recap, unless a turn started after it
#   prompt     the last prompt, and the first line of the one before
#   reply      the start of the last reply
#   questions  a "Needs you" section; "no open questions" for a reply laid
#              out heading-per-point; else up to five lines ending in "?"
# The work repo's card also shows artifacts, decisions, model, cost and
# context %, from its reply log and status-line cache; neither exists here.

WB_CARD_QUIET_AFTER=600   # a busy session with no activity this long reads "quiet"

_wb_card_age() {
  local s=$(( WB_CARD_NOW - $1 ))
  if   [ "$s" -lt 60 ];    then printf '<1m'
  elif [ "$s" -lt 3600 ];  then printf '%dm' $(( s / 60 ))
  elif [ "$s" -lt 86400 ]; then printf '%dh' $(( s / 3600 ))
  else                          printf '%dd' $(( s / 86400 ))
  fi
}

_wb_card_section() {
  local n=$(( WB_CARD_WIDTH - ${#1} - 4 )) rule
  [ "$n" -gt 0 ] || n=0
  printf -v rule '%*s' "$n" ''
  printf '\n\033[38;2;136;57;239m\033[1m── %s %s\033[0m\n' "$1" "${rule// /─}"
}

_wb_card_fit() {
  local s="${1//$'\t'/ }"
  if [ "${#s}" -gt "$WB_CARD_WIDTH" ]; then s="${s:0:WB_CARD_WIDTH-1}"; printf '%s…\n' "${s%"${s##*[![:space:]]}"}"
  else printf '%s\n' "$s"; fi
}

# _wb_card_recap <transcript> — "<epoch>\t<text>" of the latest recap (an
# away_summary or /recap's output) when no prompt came after it.
_wb_card_recap() {
  wb_reverse "$1" 2>/dev/null \
    | grep -m 24 -E '"subtype":"(away_summary|local_command)"|<command-name>/|"origin":\{' \
    | jq -rs '
        def strip: gsub("</?local-command-stdout>"; "") | sub("\\s*\\(disable recaps in /config\\)\\s*$"; "") | gsub("^\\s+|\\s+$"; "");
        def epoch: (.timestamp // "") | sub("\\.[0-9]+Z$"; "Z") | (try fromdateiso8601 catch null);
        def cmd: (.message.content | if type == "string" then (capture("<command-name>(?<c>/[^<]*)</command-name>").c // null) else null end);
        . as $e
        | first(range(0; length) as $i | $e[$i]
            | if .type == "system" and .subtype == "away_summary" then {r: .}
              elif .type == "system" and .subtype == "local_command" then
                (if (($e[$i + 1] // {}) | cmd) == "/recap" then {r: .} else empty end)
              elif .type == "user" and (.message.content | type) == "string" and (.origin | type) == "object" then {r: null}
              else empty end)
        | .r // empty | select(.content | type == "string")
        | "\(epoch // 0)\t\(.content | strip | gsub("\n+"; " "))"' 2>/dev/null
}

# _wb_card_turns <transcript> — the last exchange from the transcript's final
# 2 MiB, tagged: "P\t<line>" of the last prompt, "U\t<first line>" of the one
# before, "R\t<line>" of the reply since the last prompt. A prompt is a user
# line with string content that Jet typed (origin set, or for older
# transcripts, not a <command> wrapper), never a tool result.
_wb_card_turns() {
  tail -c 2097152 "$1" 2>/dev/null | jq -Rrn '
    def human: .type == "user" and (.message.content | type) == "string" and (.isMeta | not)
      and ((.origin | type) == "object" or (.message.content | test("^\\s*<") | not));
    reduce (inputs | fromjson? | select(type == "object")) as $e ({p: [], r: []};
      if ($e | human) then .p = ((.p + [$e.message.content])[-2:]) | .r = []
      elif $e.type == "assistant" and ($e.message.content | type) == "array" then
        .r += [$e.message.content[] | select(.type == "text") | .text]
      else . end)
    | (if (.p | length) > 1 then "U\t" + (.p[-2] | split("\n")[0]) else empty end),
      (if (.p | length) > 0 then (.p[-1] | split("\n")[] | "P\t" + .) else empty end),
      (.r | join("\n") | split("\n")[] | "R\t" + .)' 2>/dev/null
}

# _wb_card_questions — from reply lines on stdin: "N\t<line>" (a Needs you
# section), "L" (heading-per-point layout), or "Q\t<line>" (lines ending in ?).
_wb_card_questions() {
  awk 'function italic(s) { return s ~ /^[*_][^*_].*[*_]$/ }
    /^ ? ? ?(```|~~~)/ { fence = !fence; prev = "x"; next }
    fence { next }
    /^#+ / {
      match($0, /^#+/); lvl = RLENGTH
      if (nl && lvl <= nl) { nl = 0; done = 1 }
      if (!done && tolower($0) ~ /needs you/) { nl = lvl; need = 1; prev = "h"; next }
      heads++; prev = "h"; next
    }
    nl { if ($0 ~ /[^[:space:]]/) print "N\t" $0; next }
    /^[[:space:]]*$/ { next }
    {
      if (prev == "h" && italic($0)) pointed++
      if (prev != "h" && !italic($0) && $0 ~ /\?[*_)`"]*[[:space:]]*$/ && q < 5) { q++; qs[q] = $0 }
      prev = "t"
    }
    END {
      if (need) exit
      if (heads >= 2 && pointed >= 2) { print "L"; exit }
      for (i = 1; i <= q; i++) print "Q\t" qs[i]
    }'
}

# wb_card <target> <kind> <job> <ref> — the card for a row: its pane
# (target) or, on a bg row, its background session (job). Prints nothing and
# returns 1 when the row has no Claude session, so the preview falls back.
# Returns 3 when it printed only the state lines (no prompt yet).
wb_card() {
  local target="${1:-}" kind="${2:-}" job="${3:-}" ref="${4:-}" pane="" sid="" st="" st_at=0 task=""
  command -v jq >/dev/null 2>&1 || return 1
  WB_CARD_WIDTH="${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}"
  [[ "$WB_CARD_WIDTH" =~ ^[0-9]+$ ]] && [ "$WB_CARD_WIDTH" -ge 20 ] || WB_CARD_WIDTH=80
  printf -v WB_CARD_NOW '%(%s)T' -1

  if [ "$kind" = bg ] && [ -n "$job" ]; then
    sid="$(wb_registry_job_session_id "$job")" || sid=""
    wb_task_exists "$ref" && task="$ref"
  elif [ -n "$target" ]; then
    pane="$(tmux display-message -p -t "$target" '#{pane_id}' 2>/dev/null)" || return 1
    sid="$(wb_claude_panes | awk -F'\t' -v p="$pane" '$5 == p { print $6; exit }')"
    if [ -z "$sid" ] && [ -n "$(wb_claude_panes | awk -F'\t' -v p="$pane" '$5 == p')" ]; then
      sid="$(tmux show -p -t "$pane" -v @claude_session_id 2>/dev/null || true)"
    fi
    task="$(wb_session_task_file "${target%%:*}" 2>/dev/null)" || task=""
  fi
  [[ "$sid" =~ ^[A-Za-z0-9-]+$ ]] || return 1

  local reg at line transcript="" tm=0
  local -a tps=("$CLAUDE_PROJECTS_DIR"/*/"$sid".jsonl)
  [ -f "${tps[0]}" ] && transcript="${tps[0]}" && tm="$(wb_mtime "$transcript")"
  if reg="$(wb_registry_entry_for_sid "$sid")"; then IFS=$'\t' read -r st st_at <<< "$reg"; fi
  at=$(( ${st_at:-0} / 1000 )); [ "$tm" -gt "$at" ] && at="$tm"
  case "$st" in
    busy)
      if [ $(( WB_CARD_NOW - at )) -ge "$WB_CARD_QUIET_AFTER" ]; then line=$'\033[1m'"quiet $(_wb_card_age "$at")"$'\033[0m \033[2m(busy, no activity)\033[0m'
      else line=$'\033[1mbusy\033[0m \033[2m'"$(_wb_card_age "$at")"$'\033[0m'; fi ;;
    waiting) line=$'\033[1mwaiting on you\033[0m \033[2m'"$(_wb_card_age "$at")"$'\033[0m' ;;
    idle)    line=$'\033[1mdone\033[0m \033[2m'"$(_wb_card_age "$at")"$'\033[0m' ;;
    *)       line=$'\033[1mstate unknown\033[0m' ;;
  esac
  printf '%s\n' "$line"
  [ -z "$task" ] || printf '\033[2m%s\033[0m\n' "$(_wb_card_fit "task: $(wb_task_stem "$task")")"

  if [ -n "$transcript" ]; then
    local rts rtx
    if IFS=$'\t' read -r rts rtx < <(_wb_card_recap "$transcript") && [ -n "$rtx" ]; then
      _wb_card_section "Recap · $(_wb_card_age "$rts") ago"
      printf '%s\n' "$rtx"
    fi
  fi

  local -a P=() Rl=()
  local U="" tag rest l n
  [ -z "$transcript" ] || while IFS=$'\t' read -r tag rest; do
    case "$tag" in P) P+=("$rest") ;; U) U="$rest" ;; R) Rl+=("$rest") ;; esac
  done < <(_wb_card_turns "$transcript")
  if [ "${#P[@]}" -eq 0 ]; then
    printf '\n\033[2mno prompts yet\033[0m\n'
    return 3
  fi

  _wb_card_section "You asked"
  n=0
  for l in "${P[@]}"; do
    [[ "$l" == *[![:space:]]* ]] || continue
    [ "$n" -lt 6 ] || { printf '\033[2m…\033[0m\n'; break; }
    printf '%s\n' "$l"; n=$(( n + 1 ))
  done
  [ -z "$U" ] || printf '\033[2m%s\033[0m\n' "$(_wb_card_fit "before that: $U")"

  [ "${#Rl[@]}" -gt 0 ] || return 0
  _wb_card_section "Claude replied"
  n=0
  for l in "${Rl[@]}"; do
    [[ "$l" == *[![:space:]]* ]] || continue
    [ "$n" -lt 12 ] || { printf '\033[2m…\033[0m\n'; break; }
    if [[ "$l" =~ ^#+\ (.*)$ ]]; then printf '\033[1m%s\033[0m\n' "${BASH_REMATCH[1]}"; else printf '%s\n' "$l"; fi
    n=$(( n + 1 ))
  done

  local -a qn=() qq=()
  local layout=0
  while IFS=$'\t' read -r tag rest; do
    case "$tag" in N) qn+=("$rest") ;; Q) qq+=("$rest") ;; L) layout=1 ;; esac
  done < <(printf '%s\n' "${Rl[@]}" | _wb_card_questions)
  if [ "${#qn[@]}" -gt 0 ]; then
    _wb_card_section "Needs you"; printf '%s\n' "${qn[@]}"
  elif [ "$layout" = 1 ]; then
    _wb_card_section "Open questions"; printf '\033[2mno open questions\033[0m\n'
  elif [ "${#qq[@]}" -gt 0 ]; then
    _wb_card_section "Possibly open"; printf '%s\n' "${qq[@]}"
  fi
  return 0
}
