# Dotfiles and AI workflow roadmap

Last updated 2026-11-04. This is the living record of where the dotfiles and the AI workflow are heading. Plans and verdicts live in the files it links to; this page says how they fit together.

## End state

One dotfiles repo serves both the personal Mac and the Ubuntu work machine. Employer-specific material stays out of it, in a work-only layer that never lands in or is published from personal surfaces. That boundary rule holds at every step below.

## How we get there

1. **Now: the Mac is a test bed.** The Mac build ports the parts of the work machine's `wb` workbench that matter most, and tries alternatives in specific areas while the work setup keeps running unchanged. Each alternative gets a written keep-or-drop verdict.
2. **Later: full migration.** Everything in the work dotfiles repo moves into this one, choosing area by area between the Mac version and the work version using those verdicts.

**When the migration is decided:** once `/handoff` and `/decide` are built and the Mac setup has been used day to day for about two weeks, the verdicts are filled in. The migration is then decided area by area. This repo isn't built as the cross-platform version before that point.

Until then, new code stays easy to port:
- Linux-vs-Mac differences go through the shims in `scripts/.config/scripts/tmux/wb-lib/compat.sh`, never inline.
- No Mac-only tool where a portable one exists.
- Anything that can't be portable, such as decision pages sending content to claude.ai, is written down in `docs/wb-mac/comparisons.md`.

Rule: an alternative doesn't count as tested until it has a verdict in `docs/wb-mac/comparisons.md`.

## Next goal

Set 2026-11-04, once PR #2 is open:

1. Work through the open items in `docs/wb-mac/follow-ups.md`.
2. Set up GitHub across the personal repos. `gh` is now logged in on the Mac with a PAT.
3. Delete the old throwaway claude.ai pages: the two wake-up tests and the review's /decide page.
4. Check TypeScript in nvim: `ts_ls` attaches and `K` hover works.
5. A Claude Code status line on the Mac matching the work repo's. At a minimum it shows context used, the weekly and 5-hour usage limits, and the worktree and wb task of the session.

## Pieces

| Piece | What it is | Status | Where it lives |
|---|---|---|---|
| Mac picker with native status | The `wb` picker and `wb new` on `prefix+a`, carved out of wb. Status comes from Claude Code's session data, background sessions are rows, and there is a local `~/tasks` store. | Built and reviewed; in PR #2 (`feat/mac-picker-native-status` into `development`); verdicts open | `docs/plans/2026-10-26-0035-feat-mac-picker-native-status-plan.md`, `docs/wb-mac/comparisons.md`, `docs/wb-mac/follow-ups.md` |
| `/handoff` and `/decide` | One `/handoff` checkpoints and restarts the session clean, hands work to a live task by messaging, or starts a seeded background task. One `/decide` asks a batch of questions in an nvim buffer or on a claude.ai page and records the answers. | Built and reviewed; in PR #2; verdicts open | `docs/plans/2026-10-30-1353-feat-wb-handoff-and-decide-plan.md`, `docs/wb-mac/comparisons.md` sections 6–10 |
| Automatic checkpoints | Hooks write draft handoffs into the task record on compact and at the end of a session. | Idea, partly absorbed: `/handoff` already replaces `/wb-save` and `/wb-resume`, and the pick-up hook loads a checkpoint after any `/clear` | Would call the same `wb checkpoint` |
| Messaging and family coordinators | One coordinator session per family dispatches two or three workers. | Idea; messaging itself is in use for `/handoff <task>` | Builds on background rows from the picker |
| Realms | The git remote decides which task store a record goes to, and a guard blocks writes across that line. | Idea | Most likely lands with the migration |
| Go task store | A Go program owns the task store, and bash keeps the tmux and fzf glue. | Planned in the work repo | Replaces the picker plan's store seam |
| Full migration | Merge the work dotfiles repo into this one. | Decided after two weeks of using `/handoff` and `/decide` | Uses the comparison verdicts |

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

- Review follow-ups for the Mac picker, none of them blocking, are listed in `docs/wb-mac/follow-ups.md`.
- `wb new` puts worktrees in `<repo>/.worktrees/`, which nothing ignores on the Mac yet, so they show as untracked in the main checkout. A global git ignore entry would cover every repo.
- Which of automatic checkpoints, coordinators and realms gets tried on the Mac next.
- The two-week use of `/handoff` and `/decide` that the migration decision waits on starts once this branch is in daily use.
