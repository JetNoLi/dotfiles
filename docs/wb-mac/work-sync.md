# Mac changes to compare against the work repo

Last updated 2026-11-06. Jet runs similar workflow work in the work dotfiles repo, so this list exists to keep both sides from building the same thing twice. Use it now to compare and to spot overlap. Port a change only once it has a keep verdict in `docs/wb-mac/comparisons.md`.

Flow is one-way by default: Mac changes can go to the work repo as they are. Anything coming back from the work repo is stripped of employer details first, because this repo is public.

## Where to read the detail

The repo is public, so all of these can be read from the work machine. Everything below is on `development`.

- `docs/wb-mac/comparisons.md`: for each change, the Mac version, the work version and an open verdict. Its probe-findings sections record what was tested against Claude Code.
- `docs/plans/2026-10-30-1353-feat-wb-handoff-and-decide-plan.md`: the requirements and design for `/handoff` and `/decide`.
- `docs/plans/2026-10-26-0035-feat-mac-picker-native-status-plan.md`: the same for the picker.
- **`/handoff`:** `claude/.claude/skills/handoff/SKILL.md`, backed by `scripts/.config/scripts/tmux/wb-lib/handoff.sh`, `claude-pickup-hook.sh` (loads a checkpoint on start or `/clear`) and `claude-autoclear.sh` (the clean restart).
- **`/decide`:** `claude/.claude/skills/decide/` (the skill, the buffer shapes and the page spec), backed by `scripts/.config/scripts/tmux/wb-lib/decide.sh`.
- `scripts/.config/scripts/tmux/claude-hooks-merge.sh`: how the hooks are wired into `~/.claude/settings.json`.

## Already described in comparisons.md

Each section there has the Mac version, the work version, and an open verdict. Sections 6 to 10 are the handoff and decide changes.

| Change | Section |
|---|---|
| Picker status from Claude Code's session registry | 1 |
| Background sessions as picker rows, `wb new --bg` | 2 |
| The picker carved out of wb into `wb-lib/` | 3 |
| The task store seam | 4 |
| The repo resolver | 5 |
| One `/handoff` in place of `/wb-save`, `/clear` and `/wb-resume` | 6 |
| Restarting the session instead of typing `/clear` | 7 |
| Cross-session messaging instead of typing into panes | 8 |
| One `/decide` in place of `/decision-buffer`, `/decision-page` and `/review-page` | 9 |
| A claude.ai page instead of a local page | 10 |
| AeroSpace keys matched to the work machine's | 11 |

## Since comparisons.md

- **Claude Code status line** (PR #5): context %, wb task, worktree, model, effort, and the 5-hour and weekly limits. The script is `scripts/.config/scripts/tmux/claude-statusline.sh`.
- **`/decide` outside a task** (PR #7): decision surfaces are keyed by tmux session name when the session isn't a wb task.
- **`/decide` buffer opens in the agent window** (PR #9): a background agent has no pane, so the buffer used to open in the session's current window, which is usually nvim. The fix also turns off `remain-on-exit` on the new pane, since a split inherits it from the agent window and the buffer then never closed.
- **Test suite on a private tmux socket** (PRs #6 and #7): `wait_until` replaces fixed sleeps, and shellcheck runs from `tests/lint.test.sh`.
- **Global ignore for `.worktrees/`** (PR #8).

## Findings worth checking on the work side

- **Binding a task to an existing session:** a session not started by `wb new` needs `@wb_repo` and `@wb_slug` as well as `@task`, or the picker shows it as a plain session. Use the target form `-t '=<session>:'`, with the trailing colon.
- **A worker closing its own task:** `wb done` stops the agent that calls it, so a session closing itself has to schedule it, for example with `tmux run-shell -b`. Without `--close`, the empty tmux session stays open.

## Being built: family coordinators

`docs/plans/2026-11-06-1531-feat-wb-family-coordinators-plan.md` has the requirements. In short:
- A coordinator session alone writes the family decisions: cross-task decisions marked `proposed` or `in-force`, with the tasks they affect (`affects:`) and where each is discussed. Each worker writes its own status block with Phase and Holding lines.
- Nothing is in force until a session asks Jet and Jet confirms.
- Affected workers hold only the dependent work.
- Sessions learn of decisions in force automatically, and every reply says whether Jet is needed.

The shared shape, as `wb family` reads it (KTD1 in the plan):

```markdown
## Family decisions          <- in the root (coordinator) task only

### <title>
status: proposed           <- or in-force
affects: [<child stem>, ...]
discussed in: <coordinator stem>
from: <worker stem> / <worker's Decisions title>   <- when taken in from a worker
confirmed: <date>, Jet: "<reply verbatim>"         <- once in force

## Status                    <- in every member's task, written by its own session

Phase: planning | building | reviewing
Touching: <files or areas>
Holding: <what is held, and on which decision> | nothing
Updated: <date time>
```

A worker's cross-task proposal is a Decisions entry in its own task with `status: proposed` and an `affects:` line. It counts as waiting on Jet until a family decision cites it with `from:`. Done members are left out of the family.

The work side answered the overlap question on 2026-11-12 (OQ1 in the plan). It has a coordinator habit and decision messaging, but no proposed or in-force status, and will adopt the plan's rules. The two sides share one plain-text shape. The work side builds the generated family page, the day-start overview by priority and the day-end refresh first; the Mac ports them at verdict time.
