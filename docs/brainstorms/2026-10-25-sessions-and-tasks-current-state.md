# Sessions, coordination and tasks: current state and gaps

Date: 2026-10-25
Input for: ce-ideate → deep-research → ce-brainstorm
Sources: the work dotfiles repo @ `da590ea` (Ubuntu, work), `JetNoLi/dotfiles` (macOS, personal), `docs/brainstorms/2026-10-18-dotfiles-convergence-findings.md`

## Framing

The interim before the single cross-OS repo is a chance to step back and ask whether the current approach is the right one, not just how to port it. Three problem areas are in scope:

1. **Running several sessions at once.** Starting, switching, pausing and resuming many parallel Claude Code sessions.
2. **Keeping track of and coordinating sessions.** Knowing what each one is doing, which one needs you, and passing work or messages between them.
3. **A task system for long-running projects.** Durable state that outlives sessions: plans, decisions, handoffs, follow-ups, families of related work.

## How it works today

### macOS (personal)

Almost nothing. `session.sh` (fzf picker over git dirs → one tmux session per project), `notes.sh`, a few tmux binds. No agent awareness, no task store. The `wb` port was explicitly kept out of the convergence plan.

### Ubuntu (work): the `wb` workbench

A large bash system (`wb.sh` ~6.2k lines, `wb-board.sh` ~4.4k, ~16k lines of scripts total, ~50 test files, ~110 PRs) plus ~30 Claude skills.

**Sessions.** `wb new` = git worktree + tmux session + task file, linked through the tmux `@task` option. A picker (`prefix+m`) lists live and dormant sessions. `wb down` / `wb pause` / `wb done` / `wb resume` manage the lifecycle. Resume is warm: it pre-types `claude --resume <id>` from the transcripts Claude Code keeps on disk. Per-agent cgroup isolation via `systemd-run` (Linux only).

**Tracking and coordination.**
- `claude-notify-hook.sh` (UserPromptSubmit / Notification / Stop hooks) sets `@claude_working` / `@claude_blocked` on the agent's tmux pane.
- `claude-sessions.sh` is an fzf picker plus a live dashboard over every Claude pane, ranked needs-input → done → waiting → working → idle. Status also comes partly from scraping pane titles and modals, which has to be recalibrated whenever the Claude Code UI changes.
- A `claude-status.sh` tmux status-left segment, and the `claude-tmux` nvim module (~1.2k lines: jump, reply, queue, transcript, output).
- `/handoff` sends a piece of the discussion to another session: it switches to a live one or spawns one with `wb new --agent`, writes context into the target's task file, then uses `send-keys`.
- `/queue` per worktree.

**Tasks.** `~/code/tasks`, a separate local git repo of ~360 markdown task files (frontmatter + Plan / Handoffs / Decisions / Done / Follow-ups sections), with per-task locks, parent/child families, `CONCEPTS.md` per family, Jira emit, `wb board --html` (four views), `wb reconcile`, a `store-specialist` subagent, decision auto-capture (hooks + Haiku/Sonnet sweep), `/park` → capture doc → `/weekly-review`.

**Most-used loops** (transcripts, 07-01 → 09-22): `/wb-resume` 91, `/wb-save` 86, `/decision-buffer` 56, `/handoff` 27, `/close-out` 19.

**Direction already set (2026-10-17).** Delete unused features, then a Go package owns task-store reads and writes (bash stays for tmux/worktree/fzf glue), with a per-task / per-family browser page as its first consumer. Plan: `docs/plans/2026-10-17-2223-feat-wb-go-store-and-task-page-plan.md` in the work repo.

## Gaps

### Session management
- **Linux only.** About 30 Linux-only dependencies (`flock`, `date -d`, `stat -c`, `/proc`, bash 4+, `systemd-run`). The Mac has none of it.
- **Saving and resuming is manual.** The two most-used skills are save/resume around a manual `/clear`. That points to friction, not value. Automatic saving (`feat-wb-implicit-handoff`) is planned but not built.
- **Open threads:** `wb down --all` / `wb up` (day bookends) and task recall ("mention a task anywhere → its context comes back").

### Tracking and coordination
- **Status is inferred, not reported.** It's half hooks, half scraping pane titles and modals. That breaks when Claude Code's UI changes, and the code already notes it needs recalibration.
- **Pull, not push.** You find out an agent needs you by looking at the picker, dashboard or status bar. Nothing reaches you when you're away from the terminal or on another machine.
- **Talking to agents means typing into tmux.** Handoff and replies use `send-keys` into panes, which is fragile (see the leading-dash fix in #80). Fan-out to several targets, instructing a live agent, and non-blocking handoff are all still open.
- **Rebuilding context by hand.** The Go plan's problem frame: when coming back to a task, Jet scrolls the Claude window, hunts browser tabs and asks the agent to summarise.
- **Possible overlap with Claude Code itself.** Claude Code now has some native coordination: listing and messaging other local sessions, background and cloud sessions, Remote Control, worktree isolation, named sessions and resume. None of it has been checked against what wb hand-builds. *Needs research.*

### Task system
- **Size and upkeep.** 183 planned against 22 doing; schema drift; three awk writers; a store-wide board that isn't used; about 40 PRs in October went to the tooling itself. The cost of keeping the system running is a gap in its own right.
- **Can't follow you to another machine.** The task store has no remote by design: the personal/employer boundary rule is "deliberately the last decision". A single dotfiles repo for both machines forces that decision, at least for what the tooling assumes about where tasks live.
- **Depends on the tmux setup.** Tasks are tied to tmux sessions, worktrees and the work repo layout (`~/code/...`), so the same system doesn't apply easily to personal projects or non-code projects (learning-os, research).
- **Possible overlap with the learning-os plan** (option B, review Sun 29 Nov): decide whether personal long-running projects belong there or here.

## Questions for ideation and research

1. What does Claude Code now do natively for many sessions and coordinating them, and which parts of wb would that make unnecessary?
2. Which tools already solve "many parallel agents": agent orchestrators and dashboards, tmux/zellij session managers, multiplexers built for agents?
3. Which task trackers suit agents: markdown or git-backed issue trackers that agents read and write (beads-style), Taskwarrior, GitHub Issues/Projects, Linear?
4. Should status be pushed instead of scraped: hooks feeding a small state file, a daemon, notifications to the phone?
5. What's the smallest system that keeps save/resume, handoff and the task record, works on both OSes, and respects the personal/employer boundary?
