# Dotfiles and AI workflow roadmap

Last updated 2026-10-27. This is the living record of where the dotfiles and the AI workflow are heading. Plans and verdicts live in the files it links to; this page says how they fit together.

## End state

One dotfiles repo serves both the personal Mac and the Ubuntu work machine. Employer-specific material stays out of it, in a work-only layer that never lands in or is published from personal surfaces. That boundary rule holds at every step below.

## How we get there

1. **Now: the Mac is a test bed.** The Mac build ports the parts of the work machine's `wb` workbench that matter most, and tries alternatives in specific areas while the work setup keeps running unchanged. Each alternative gets a written keep-or-drop verdict.
2. **Later: full migration.** Everything in the work dotfiles repo moves into this one, choosing area by area between the Mac version and the work version using those verdicts.

Rule: an alternative doesn't count as tested until it has a verdict in `docs/wb-mac/comparisons.md`.

## Pieces

| Piece | What it is | Status | Where it lives |
|---|---|---|---|
| Mac picker with native status | The `wb` picker and `wb new` on `prefix+a`, carved out of wb. Status comes from Claude Code's session data, background sessions are rows, and there is a local `~/tasks` store. | Planned, not started | `docs/plans/2026-10-26-0035-feat-mac-picker-native-status-plan.md` |
| Automatic checkpoints | Hooks write draft handoffs into the task record on compact and at the end of a session, and `/wb-save` and `/wb-resume` become optional. | Idea | Depends on the picker's task store and seam |
| Messaging and family coordinators | Claude's cross-session messaging replaces send-keys handoffs. One coordinator session per family dispatches two or three workers. | Idea | Builds on background rows from the picker |
| Realms | The git remote decides which task store a record goes to, and a guard blocks writes across that line. | Idea | Most likely lands with the migration |
| Go task store | A Go program owns the task store, and bash keeps the tmux and fzf glue. | Planned in the work repo | Replaces the picker plan's store seam |
| Full migration | Merge the work dotfiles repo into this one. | Later | Uses the comparison verdicts |

Dependencies, in short:
- Checkpoints need the task store.
- Coordinators need background rows.
- The migration needs the verdicts.
- The Go store can proceed on its own.

## Background material

- `docs/brainstorms/2026-10-25-sessions-and-tasks-current-state.md`: how the work machine's `wb` handles sessions and tasks today, and its gaps.
- `docs/ideation/2026-10-25-parallel-sessions-and-tasks-ideation.html`: seven ranked directions.
- `reports/AI agent workflow alternatives.md` and `research_notes/AI agent workflow alternatives/`: what Claude Code offers natively, other orchestrators, task trackers, notifications and personal/work separation, as of October 2026.
- Walkthrough pages: a day on the new workbench (https://claude.ai/artifact/8XrwF9oHUjipYTuUGXvk6Y) and the task store's shape (https://claude.ai/artifact/LWzSgMaTLf13u1Z4esLYef).

## Decisions so far

- The picker's code lives in this repo from now on. It is carved out of wb, not copied whole, and goes through a boundary review when it crosses over.
- On the Mac, `prefix+a` opens the picker and `prefix+m` stays as the folder opener.
- Claude Code's agent view sits underneath the picker as a data source, not in its place.
- Port as bash now; the Go store comes later behind one seam.
- Parking a task stops its background agent.

## Open threads

- Whether background sessions appear in Claude Code's session registry. The picker plan settles this when it is built.
- Which of checkpoints, messaging and realms gets tried on the Mac next.
- When the full migration starts.
