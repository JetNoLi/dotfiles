# wb on the Mac: comparisons with the work build

The Mac picker (`scripts/.config/scripts/tmux/wb`) is a test bed for the later migration into one dotfiles repo. Each section below covers one deliberate difference from the work machine's `wb`: what differs, what to watch while using it, and a keep-or-drop verdict. A verdict stays **open** until there has been enough day-to-day use to judge it.

Plan: `docs/plans/2026-10-26-0035-feat-mac-picker-native-status-plan.md`. Built from the work repo at `481d6ed`.

## 1. Native status from Claude Code's session registry

**What differs.** wb works out agent status by reading pane titles and screen text, which needs recalibrating whenever Claude Code's UI changes. The Mac build reads `~/.claude/sessions/<pid>.json` first: one file per running session, with its status and the tmux pane it runs in. An entry counts only while its pid runs with the same start time. Registry `waiting` means needs you, `busy` means working, and `idle` or anything unknown means idle. wb's own pane markers still win (`done` for a long turn that finished, an nvim decision buffer), and panes the registry can't place fall back to wb's title-and-screen scrape. The scrape now finds Claude through the process tree, because `pane_current_command` shows the version string.

**What to watch.**
- Idle panes must never show as working. That was the old failure.
- Whether the registry's status ever lags what the pane shows.
- Whether a Claude Code update renames or drops the registry fields. The file is internal and undocumented.
- How often the scrape fallback fires. If it never does, it could be dropped.

**Verdict:** open.

## 2. Background sessions as rows, and `wb new --bg`

**What differs.** wb can't see `claude --bg` sessions. Here every background session in the registry is a row tagged `(bg)`, nested under the task it belongs to (matched by session id in `claude_sessions:`, then by worktree cwd), or shown on its own in its cwd's repo group. `wb new --bg` starts the agent with `claude --bg -n <session>` in the new worktree and records the full session UUID as `@primary`. Enter attaches in the task session's agent window, or jumps to an existing attach. `p` and `ctrl-x` stop the background agent before anything else. A session attached in a pane shows once, as its pane.

**What to watch.**
- Whether background agents are actually useful for Jet's work, or attached sessions are used every time anyway.
- Idle background sessions stop after about an hour and still list as idle rows. Check that this reads clearly.
- `--bg` refuses to start in a folder Claude doesn't trust. A worktree under a trusted repo is trusted, but a repo that was never opened in Claude fails with Claude's own message.

**Verdict:** open.

## 3. The carved-out module

**What differs.** wb is one 7,000-line `wb.sh` plus siblings. The Mac build carries over only what the picker and `wb new` reach, split into `wb-lib/` files (compat, repos, store, status, rows, picker, lifecycle, card) behind a bash 5 entry point. Left behind: board, capture, weekly review, breakdown, families' reseed, decision propagation, the ticket-link flag, the reply log and the status-line cost cache (KTD9). Also dropped from `wb done`: the gitignored-file sweep, because it depends on the decision buffer this repo doesn't have.

**What to watch.**
- Anything reached for on the Mac that only exists in the work build.
- The `wb done` sweep: gitignored files in a worktree are deleted with it.

**Verdict:** open.

## 4. The task store seam

**What differs.** wb's code reads and writes task files wherever it needs to. Here every task read and write goes through `wb-lib/store.sh`, so the planned Go store can replace that one file. The store is a local `~/tasks` with no remote. Records use the Ubuntu format plus a `repo_path:` field.

**What to watch.**
- Any new code that touches `~/tasks` outside `store.sh`. Check with `grep -n TASKS_DIR wb-lib/*.sh`.
- Whether records move cleanly to the Ubuntu store at migration.

**Verdict:** open.

## 5. The repo resolver

**What differs.** wb assumes every repo sits directly in one fixed code folder, named by its directory. The Mac build finds repos the way `session.sh` does: `~/dotfiles`, plus every repo a pruned `.git` search finds under `~/Desktop`, including nested ones. The roots can be overridden with `WB_REPO_ROOTS`. A name two repos share is refused, with both paths listed. `wb new` stores the full path as `repo_path:`, and records without it (from Ubuntu) go back through the resolver.

**What to watch.**
- The duplicate basename that exists today, and how often the refusal gets in the way.
- How long the search takes as `~/Desktop` grows. It runs once per picker refresh.

**Verdict:** open.

## Other differences made while building

- **The resume id prefers `@primary`.** Since #116, wb ignores `@primary` and resumes the transcript with the newest activity, because its `@primary` came from a pane option that went stale after `/clear`. Here `@primary` comes from the session registry when `wb down` runs (or from `--bg`), which is current at that moment, so it wins when its transcript exists (KTD11). Watch for a parked task resuming the wrong conversation.
- **The context card reads the transcript.** wb's card takes the last prompt and reply from its reply log. Here they come from the conversation's own `.jsonl`, so the card needs no hook-written log. It shows state, recap, the last two prompts, the start of the reply and open questions, but no artifacts, decisions, model or cost.
- **The PR check in `wb down`** runs `gh` under a 10-second watchdog with no token fallback. Until gh is authenticated on the Mac it always reads as "no open PR", so a task never moves to review on its own.

## Probe findings (2026-10-28, Claude Code 2.1.312)

These answer the plan's deferred questions.

- **Do background sessions appear in the registry?** Yes, with `kind: "bg"`, no `tmux` field, and `jobId` set to the short id `claude --bg` prints, which is the first 8 characters of `sessionId`. So the planned `claude agents --json --all` step was not built: the registry already places every background session. (`claude agents --json --all` took about 0.1s, well under the planned 2-second watchdog.)
- **Do background sessions inherit `TMUX_PANE`?** No. Their parent is Claude's `bg-pty-host`, and their environment has no `TMUX` or `TMUX_PANE`. The notify hook is ported unchanged and does nothing for them.
- **Does the registry ever report `waiting`?** Yes, for a live session at a permission prompt. AE1 holds as written.
- **Does `claude --bg -n <name>` need a prompt?** No. It prints `backgrounded · <id> · <name> (idle — send a prompt to start)` and starts idle. It writes no transcript until the first prompt.
- **How does an attached session look?** The registry entry doesn't change (still `bg`, still no `tmux`). The pane's child process is `claude attach <id>`, which is how the picker shows it once.
- **After `claude stop`:** the registry file is gone, and `claude agents --json --all` lists the session as stopped or done.
- **`procStart`** is UTC in the C locale. `TZ=UTC LC_ALL=C ps -o lstart=` matches it after trimming trailing spaces.
- **Other registry statuses** (failed, stopped, completed): none seen. Unknown values map to idle.
