# wb on the Mac: comparisons with the work build

The Mac picker (`scripts/.config/scripts/tmux/wb`) is a test bed for the later migration into one dotfiles repo. Each section below covers one deliberate difference from the work machine's `wb`: what differs, what to watch while using it, and a keep-or-drop verdict. A verdict stays **open** until there has been enough day-to-day use to judge it.

Plan: `docs/plans/2026-10-26-0035-feat-mac-picker-native-status-plan.md`. Built from the work repo at `481d6ed`.

## 1. Native status from Claude Code's session registry

**What differs.** wb works out agent status by reading pane titles and screen text, which needs recalibrating whenever Claude Code's UI changes. The Mac build reads `~/.claude/sessions/<pid>.json` first: one file per running session, with its status and the tmux pane it runs in. An entry counts only while its pid runs with the same start time. Registry `waiting` means needs you, `busy` means working, `idle` means done (green: at its prompt, turn over, as the work machine's picker shows it), and anything unknown means idle. wb's own pane markers still win (`done` for a long turn that finished, an nvim decision buffer), except that the hook's needs-input marker yields to registry `busy`: approving a permission prompt fires no hook, so the marker would otherwise stay "needs you" while the agent works. Panes the registry can't place fall back to wb's title-and-screen scrape. The scrape now finds Claude through the process tree, because `pane_current_command` shows the version string.

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

## 6. One `/handoff` instead of `/wb-save`, `/clear` and `/wb-resume`

Plan: `docs/plans/2026-10-30-1353-feat-wb-handoff-and-decide-plan.md`.

**What differs.** The work machine checkpoints with `/wb-save`, then Jet runs `/clear`, then `/wb-resume`. Here `/handoff` writes the checkpoint (Done, In flight, Next, Open decisions) through `wb checkpoint`, and when its turn ends the session restarts clean and opens with "Picked up … Next: … Go ahead?". `/handoff --keep` only writes. The same verb hands work to another live task or starts a new one. The pick-up instructions travel in the SessionStart hook's injected text, so a manual `/clear` still picks up.

**What to watch.**
- Whether the one-command loop is used as often as the three-step one was (91 resumes and 86 saves on the work machine from July to September).
- Pick-ups that state a stale plan without naming the entry that made it stale.
- A restarted session losing a model or effort setting. Only the permission mode carries over.

**Verdict:** open.

## 7. Restarting the session instead of typing `/clear`

**What differs.** No hook, skill or setting can run `/clear`, and auto mode blocks an agent typing into its own pane. So a Stop hook (`claude-autoclear.sh`) restarts the work instead: a pane is respawned with `claude "<pick-up prompt>"`, a background job is stopped and started again under its name. The helper gives up, keeping the checkpoint, when Jet has typed into the input line, a new turn has started, the request is over 2 minutes old, background tasks are running or a `/decide` buffer is open. It logs why to `$WB_STATE_DIR/handoff.log`.

**What to watch.**
- Restarts that wiped something Jet was about to send. The input-line read relies on Claude's `❯` plus no-break space and dim placeholder, which a UI change could break.
- Give-ups that shouldn't have happened. The log says which check fired.
- Whether the 1.5-second "clearing…" notice is worth its delay.

**Verdict:** open.

## 8. Cross-session messaging instead of typing into panes

**What differs.** The work machine's `/handoff` types into the target's tmux pane and leans on a Linux clipboard tool. Here the entry goes into the target's task file (`wb handoff-to`) and a short `SendMessage` points the live session at it. A busy session reads it between steps, and an idle one starts a turn. With no live session the entry waits in the file. `/handoff new` starts a background task seeded with a checkpoint, which begins its Next step without asking.

**What to watch.**
- Messages held for approval when the two sessions run in different permission modes. None were held in the test run.
- Pane sessions found by tmux session in `ListAgents`, since they don't carry the stem as their name.
- Background tasks from `/handoff new` that start on the wrong step because the seeded Next was vague.

**Verdict:** open.

## 9. One `/decide` instead of `/decision-buffer`, `/decision-page` and `/review-page`

**What differs.** One skill agrees the direction in chat, then picks the surface from the questions' shape: an nvim buffer for a few quick answers or a run-and-paste loop, a page for options, evidence or many items, or both. Two buffer shapes replace six. Every answer goes into the task's Decisions section through `wb decision`, which replaces an entry with the same title. While a surface is open, the picker shows the task as needing Jet (`$WB_STATE_DIR/needs-you/<stem>`). The buffer runs as a background command, so its closing wakes the session.

**What to watch.**
- Wrong surface choices, the problem the work skills' routing tables kept hitting.
- Whether two buffer shapes are enough, or a findings or interview shape is missed.
- Items asked without options, pros and cons and a recommendation. Jet asked for all three on every item.
- A candidate third shape from the work side (2026-11-12): an interview buffer of free-text questions, each saying why it is asked and the default if left blank. It worked well there on 5 Nov for reconstructing a morning from memory. It would sit alongside the rule that decision items carry options, pros and cons and a recommendation. Decide at the verdict.

**Verdict:** open.

## 10. A claude.ai page instead of a local page

**What differs.** The work machine's pages are local HTML, answered by pasting a block back or through a local server. Here a private claude.ai artifact renders a published `spec.json` in two layouts and saves each answer to its own `db` as Jet clicks, so a page can be finished on a phone. Submit writes `meta/submitted` and sends a comment to Claude, which wakes the session that published it. After a `/handoff` restart that wake isn't armed, and Jet types "done". Page content goes to claude.ai, so pages are only for the Mac's personal repos (R21).

**What to watch.**
- The wake took about a minute in the test. Whether that's fast enough, or whether "done" gets typed anyway.
- The watch's auto-reply posting misleading "recorded" notes in the thread.
- Pages left open after a restart that nobody collects. The pick-up lists them.

**Verdict:** open.

## 11. Window management: AeroSpace on the Mac, Forge and Run or Raise at work

**What matches (synced 2026-11-04).** The Mac's Option key plays the part of the work machine's Super key, and sits in the same physical spot. With it, the two machines share these keys:
- **App letters:** `i` Ghostty, `b` browser, `v` VS Code, `c` Slack, `t` Teams, `q` Claude, `y` Spotify, `e` files, `o` email. The Mac also has `p` Postman and `u` Figma, which are free at work.
- **Focus, move and swap:** `hjkl` focuses, `Shift+hjkl` moves and `Ctrl+hjkl` swaps.
- **Workspaces:** eight, on `1 2 3 4 A S D F`, with `Shift` sending the window there.
- **Close:** `Shift+X`.
- **Layout extras:** float, split toggle, stacked and tabbed on `C G S T`, with Option+Cmd on the Mac and Super+Alt at work.

On both machines, `ctrl+hjkl` stays with tmux and nvim.

**What differs, kept on purpose.**
- **Workspaces per monitor.** On the Mac, 1–4 stay on the laptop screen and A/S/D/F on the external, so a key switches one screen. At work, every workspace spans both monitors and a key switches both. GNOME can't do separate sets per monitor, and the work plan names that as a limitation.
- **Option+Tab** jumps back to the last workspace. At work, Super+Tab is still GNOME's app switcher, so the same chord does different things. Of all the differences, this one is the likeliest to trip you up.
- **Option+Shift+Tab** moves the whole workspace to the other monitor. GNOME has nothing like it, because its workspaces already span both screens.
- **Resize** is on Option+- and Option+= on the Mac. At work it is on Forge's default keys, which this setup leaves alone.
- **Service mode** (Option+Shift+;) is a one-key layer. Esc reloads the config, R resets the layout, F floats, Backspace closes every other window, Option+Shift+hjkl nests the window together with its neighbour, and up/down change the volume. Work has no key layers. Its nearest equivalent is Forge's split keys (Super+Alt+Z/V).
- **App keys open or focus the app** (`open -a`). At work, Run or Raise also cycles through the app's windows when pressed again.
- **No focus border** on the Mac. Work draws a thin grey one.

**What to watch.** Whether Option+Tab's different meaning causes mistakes, and whether resize or back-and-forth are worth adding at work.

**Verdict:** open.

## Work-skill behaviours and where they went (R23)

Every behaviour of the six work skills is either covered by the plan's R1–R22 or left out on purpose:

| Work behaviour | Here |
|---|---|
| `/wb-save` finds the task from `@task`, never the folder | R1, through `wb task-for-session` |
| Done / In flight / Next, plus a `run` block for the next command | R1; the `run` block is kept in `/handoff` |
| `/wb-save` reviews shelved decision drafts first | Left out: `/wb-decide` drafting is out of scope |
| `[wb-propagate]` messages noted as Received | Left out with `/wb-decide` |
| `/wb-resume` reads the newest rich entry and checks for gaps after it | R3, R4 |
| `/wb-resume` with no rich entry falls back to the auto entries | Left out: with no checkpoint, nothing is injected and the session starts plain |
| `/handoff` infers repo and slug, writes a first action and rich context | R10, through `wb new --bg --handoff` |
| `/handoff` types into the target pane | Replaced by messaging (R7–R9) |
| Align first, in chat | R12 |
| Six buffer shapes; every question says why | Two shapes; options, pros and cons, and a recommendation per item |
| Runtime check before opening a buffer | `wb decide-buffer` refuses outside a task or a tmux session |
| Rewrite the buffer fresh on a second round | Left out: unanswered items are asked about in chat |
| Fold answers in, then move the decision doc | R18: answers go straight into Decisions |
| Feedback and learnings ledgers | Left out: lasting feedback goes into Claude's memory |
| Companion HTML beside a buffer | R13's "both" |
| Decision page publish optional, paste-back close | R15–R17: always a claude.ai page, Submit or "done" |
| Review page with a local server | R15's shared-verdict layout |

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

## Probe findings: `/handoff` auto-clear (2026-10-30, Claude Code 2.1.314)

U3's test run used real Claude in a throwaway task on a private tmux server (`tmux -L`), so the real server and `~/tasks` were never touched. Every check passed, so KTD2 and KTD4 stand and no fallback was built.

- **Does the helper survive `respawn-pane -k` when launched with `tmux run-shell -b`?** Yes. It went on to record the new session as `@primary` after the respawn.
- **Does a respawned `claude "<prompt>"` get the SessionStart `additionalContext` and act on it?** Yes. It opened with "Picked up the checkpoint from 18:53 (0 minutes ago). Next: … Want me to go ahead?" and waited. It knew a codeword given before `/handoff` only through the checkpoint, so the context was clean.
- **Does auto mode let it through?** Yes, both halves. `wb checkpoint` and `wb clear-request` ran as "Allowed by auto mode", and the restart is the hook's, not a tool call. The restarted session came back in auto mode, read from the Stop hook's `permission_mode`.
- **Does the Stop hook fire before Jet could type?** The pane restarted 1–2 seconds after the turn ended, behind a 1.5-second "clearing…" notice. The helper checks the input line before and after that notice.
- **Does `claude` resolve in a respawned pane?** The Stop hook passes its absolute path from Claude's own environment, so the pane's PATH doesn't matter.
- **Can a background job be stopped and started again by name (KTD4)?** Yes. A `--bg` job that ran `/handoff` was stopped (`state: done`), and a new job started under the same name with the pick-up prompt. It stated the checkpoint and waited (`state: blocked`), and became `@primary`. A `--bg` job started from a shell gets that shell's environment, so `TASKS_DIR` and `WB_STATE_DIR` reached its hooks.
- **Manual `/clear` (KTD5's `source=clear`)** also works: the first reply after it stated the checkpoint and asked to go ahead.
- **How to read the input line.** Claude's live input line is `❯` followed by a no-break space (U+00A0). Transcript lines use `❯` and a plain space, so a plain `❯ ` match finds Jet's earlier prompts instead. Empty, it shows nothing or a dim (`ESC[2m`) placeholder or next-prompt suggestion such as "write hello.txt". Typed text isn't dim. With no input line on screen (a dialog, say), the helper doesn't restart. The first probe run caught the plain-space mistake: a suggestion read as typed text, and the helper gave up.
- **Claude Code sets `CLAUDE_PID` and `CLAUDE_CODE_SESSION_ID`** for the commands it runs. `wb task-for-session` uses `CLAUDE_PID` to find its own registry entry.

## Probe findings: `/decide` buffer (2026-10-30, Claude Code 2.1.314)

U4's check, run the same way on a private tmux server.

- **Does a background command's exit wake an idle interactive session?** Yes. `/decide` ran `wb decide-buffer` with `run_in_background`, ended its turn, and sat idle ("1 shell still running"). When the nvim split closed, the session started a turn by itself, read the answers and recorded them. The plan's assumption holds, so the buffer needs no "done".
- **Surface choice (AE7):** three yes/no questions went to the buffer without being asked.
- **Picker:** while the buffer was open, the task's pane read needs-input from the needs-you file. It was idle by the registry.
- **Recording:** one `wb decision` per item. The blank item was recorded as "default taken", Jet's note was kept verbatim, and `wb decide-clear` removed the needs-you file.
- **tmux 3.5a quirk:** `display -p -t <pane>` for a pane that's gone prints nothing and exits 0, so code that waits on a pane compares the printed id.

## Probe findings: cross-session messaging for `/handoff <task>` (2026-10-30, Claude Code 2.1.314)

U5's test run. This session sent with `SendMessage` to real probe sessions on a private tmux server: panes in default (manual) and auto mode, and a `--bg` job in auto mode.

- **Idle targets:** every one, the default-mode pane included, started a turn with the message and replied. Nothing was held for approval, even though the sender ran in auto mode.
- **Mid-turn targets:** a pane and a background job, each partway through a multi-step turn, read the message between steps. Each finished its work and then acted on the message. Nothing was interrupted.
- **Intact:** a body with non-ASCII text (`alpha-βeta-γamma-✓-12345`) reached the receiver's transcript byte for byte.
- **So R9's fallback (switching Jet to the session with the context on the tmux buffer) was not built.** Messaging worked for both kinds of session.
- **Names (KTD11).** A pane session started without `-n` gets an automatic name (`ac-b3`, `pb-b7`), not the wb stem. Its `ListAgents` row does show `tmux <session>:@…`, and wb's session name is the stem. `/handoff <task>` matches either a row named for the stem (background jobs, which `wb new --bg` names) or a row whose tmux session is the stem. No launch needs `-n`.
- **End to end:** `/handoff probe--pb` from one task wrote the `from probe--ac` entry, messaged the unnamed live session, and the receiver did the work. `/handoff new probe-child` made the worktree, session and seeded task (parent set), and its background Claude began the Next step without asking.

## Probe findings: the `/decide` page and its Submit wake (2026-10-30, Claude Code 2.1.314)

U6's wake test used two throwaway pages, one per layout, published with the `db` and `comments` capabilities. Jet pressed Submit himself.

- **Can page code send a comment to Claude?** Yes. The `comments` capability has `sendToClaude`, editors only and only from the viewer's own click, with `canSendToClaude` to check first. Submit uses it after writing `meta/submitted`.
- **Does Submit wake an idle session that published the page?** Yes. The watch's auto-reply posted a one-line acknowledgement in the thread, and then the session got an `artifact-auto-react` notification that started a turn. About a minute passed between the click and the turn. **Proven, so Submit is the default, and "done" is the fallback.**
- **After a U3 restart?** No. The restarted session re-watches the page with `ArtifactComments`, but a watch arms auto-replies only when the link is in Jet's own message. The pick-up hook's text doesn't count. So after a restart, `/decide` tells Jet to type "done" (or to paste the link back, which arms it). The "done" path, with the session the probe restarted, recorded the answered rows and left the rest open.
- **A session busy in a tool call** when Submit arrived got no turn for it. The auto-reply still answered in the thread. "done" covers that case.
- **The auto-reply can mislead.** It has no task context and may say it "recorded" answers that never reach the task file. The skill tells Claude to ignore that and record them itself.
- **Saving:** answers wrote per click (notes after a 0.6-second pause) and survived a reload. `meta/submitted` held the answered count.
- **Content, from Jet's answers:** title-only rows and items without trade-offs came back as "need more info". Every item now needs options, pros and cons, and a recommendation (`references/page-spec.md`), and a note asking for information counts as unanswered.
- **Page name:** the template's `<title>` names the artifact over the publish title, so the skill sets it from the spec.
