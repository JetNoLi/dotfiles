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

## In design: family coordinators

`docs/plans/2026-11-06-1531-feat-wb-family-coordinators-plan.md` has the requirements. In short:
- A coordinator session owns one record per family, covering cross-task decisions with their status, the tasks they affect, and where each is discussed.
- Nothing counts as decided until a session asks Jet and Jet confirms.
- Affected workers hold only the dependent work.
- Sessions learn of confirmed decisions automatically.

Before that plan goes further, it needs one answer from the work side: does the work repo already have, or plan, something that overlaps it? If it does, bring back only how it behaves, not employer details.
