# Third-party orchestrators and multiplexer setups for parallel AI coding agents (as of Oct 2026)

Source-quality note: many "best of 2026" comparison posts are written by vendors who appear in their own lists. The dev.to/Nimbalyst article is by Karl Wirth, CEO of Nimbalyst (disclosed). The amux.io post is by amux/Mixpeek. superset.sh, parallelcode.app, termdock.com and crystl.dev pages are also vendor-authored. Treat their rankings with caution. Their factual claims about other tools (platform, license) are mostly consistent across sources.

## Per-tool comparison (what it does, isolation, status, handoff, task record, platforms, license, health)

### Takeaway
Of the tools found, the terminal-native ones that run on both macOS and Ubuntu and are closest to a tmux + worktree + markdown workbench are workmux, agent-deck, Claude Squad and ccmanager. Conductor is macOS-only. Vibe Kanban is community-maintained after its company shut down. Opcode is no longer actively developed. Claude Code's own agent view (May 2026) now covers much of the "which agent needs input" job natively.

### Cited Findings

**Claude Code native (baseline to compare against)**
- Agent view (`claude agents`) is one screen for all background sessions, showing what's running, what needs input, and what's done. Row states are Working, Needs input (yellow: question, permission, sandbox or MCP prompt), Idle, Completed, Failed and Stopped. Groups are Pinned, Ready for review, Needs input, Working and Completed. — [Claude Code Docs: agent view](https://code.claude.com/docs/en/agent-view)
- When a background session starts editing, Claude moves it into its own git worktree under `.claude/worktrees/`. This is skipped for sessions backgrounded from an open terminal, for sessions already in a worktree, and outside git repos unless a `WorktreeCreate` hook is set. `worktree.bgIsolation: "none"` disables it. Deleting a session keeps the worktree if it has uncommitted or unpushed work. — [Claude Code Docs](https://code.claude.com/docs/en/agent-view)
- A supervisor process keeps sessions running after the terminal closes. Unattended finished sessions are stopped after about an hour but resume from disk. Sessions survive sleep but not shutdown. `/bg` backgrounds a session and `/fork` copies a conversation into a new background session. It is a research preview, each session uses quota independently, and subagents and teammates don't show as separate rows. — [Claude Code Docs](https://code.claude.com/docs/en/agent-view)
- Agent view shipped in Claude Code v2.1.139 as a research preview in May 2026. It has `claude --bg`, `claude attach <id>` and `claude rm <id>`, and there is no cross-machine dashboard. — [aq.dev guide](https://aq.dev/guides/claude-code-agent-view-and-background-sessions/); [DeepWiki summary](https://deepwiki.com/pleaseai/claude-code-docs/10.3-background-sessions-and-agent-view); [dsebastien.net](https://www.dsebastien.net/claude-code-agent-view-one-screen-for-every-background-session/)
- Claude Code has built-in `claude --worktree --tmux` flags. — [crystl.dev tmux guide (vendor)](https://crystl.dev/guides/tmux-for-ai-agents/)
- Claude Code Agent Teams is labelled experimental and off by default, and it uses a shared repo rather than separate worktrees. — [amux blog (vendor)](https://amux.io/blog/best-multi-agent-orchestrators-2026/). It supports only tmux as a multiplexer (v2.1.32+), and there is an open feature request for Zellij. — [claude-code issue #31901](https://github.com/anthropics/claude-code/issues/31901)

**workmux (raine/workmux)**
- Pairs git worktrees with tmux windows ("git worktrees + tmux windows for zero-friction parallel dev"). `add` creates a worktree plus window. `merge` merges and removes the worktree, window and branch. It also has a dashboard and persistent sidebar, a `/worktree` skill that delegates tasks to worktree agents, post-create hooks, copy/symlink of `.env` or `node_modules`, optional container or VM sandboxing, LLM-generated branch names, and `resurrect` after a crash. — [GitHub raine/workmux](https://github.com/raine/workmux)
- Status shows in tmux window names: working 🤖, waiting for input 💬, done ✅. It supports Claude Code, Codex, OpenCode, Copilot CLI, Gemini CLI and others. Backends are tmux (primary), Zellij, Kitty and WezTerm. — [GitHub raine/workmux](https://github.com/raine/workmux)
- Handoff features: `--fork` carries a conversation into a new worktree, `--continue` resumes the last conversation, and `--json` gives provisioning receipts. I saw no dedicated durable task-file feature in the part of the README I read. — [GitHub raine/workmux](https://github.com/raine/workmux)
- MIT. Installs via Homebrew (macOS/Linux), a bash script, Cargo, mise, Nix or prebuilt binaries. — [GitHub raine/workmux](https://github.com/raine/workmux)
- It was mentioned by users in the HN thread on tmux + Markdown spec workflows. — [HN 47218318](https://news.ycombinator.com/item?id=47218318)

**agent-deck (asheshgoplani/agent-deck)**
- A Go/Bubble Tea TUI using tmux as its session layer. It manages Claude Code, Gemini CLI, OpenCode and Codex. It has groups, fuzzy search, session forking, git worktrees, cost tracking, MCP and skills managers, a Docker sandbox, a web UI, and archive/restore. It can use a separate tmux socket so it stays apart from your own tmux server. — [GitHub agent-deck](https://github.com/asheshgoplani/agent-deck)
- Status comes from polling or parsing output: running ●, waiting ◐, idle ○, error ✕. Codex and pi report through hooks instead. — [GitHub agent-deck](https://github.com/asheshgoplani/agent-deck); [CSDN write-up](https://deepseek.csdn.net/6a31fd31662f9a54cb802be4.html)
- Has the strongest handoff and messaging model found. A "conductor" is a persistent agent session that monitors other sessions, answers routine questions and escalates. A heartbeat runs every 15 minutes, and a notifier alerts the parent conductor when a child changes state (to waiting or error). Watchers forward webhook, GitHub, ntfy and Slack events. Remote control works through Telegram, Slack, Discord and Mattermost. Each conductor keeps a `task-log.md` action log, which is the closest it has to a durable task record. — [GitHub agent-deck](https://github.com/asheshgoplani/agent-deck)
- Supports MCP socket pooling to share MCP processes across sessions. — [sourcepulse](https://www.sourcepulse.org/projects/21694884)
- Runs on macOS and Linux (Windows via WSL). MIT. Installs via Homebrew or Go. Releases range from v0.21.0 to v1.7.21, so it is iterating quickly. — [GitHub](https://github.com/asheshgoplani/agent-deck); [newreleases v1.7.21](https://newreleases.io/project/github/asheshgoplani/agent-deck/release/v1.7.21)

**Claude Squad (smtg-ai/claude-squad, `cs`)**
- A terminal TUI that runs Claude Code, Codex, Gemini, Aider, OpenCode and Amp. Each task gets its own tmux session and git worktree. It has a session list, preview and diff tabs, commit/push/checkout, pause/resume, and background auto-accept ("yolo") mode. It needs tmux and `gh`, and installs via Homebrew or curl. — [GitHub claude-squad](https://github.com/smtg-ai/claude-squad)
- License is AGPL-3.0 per the repo; the amux vendor post says MIT, which is wrong per the repo. — [GitHub](https://github.com/smtg-ai/claude-squad); [amux blog](https://amux.io/blog/best-multi-agent-orchestrators-2026/)
- Health: about 8.7k stars, 625 forks, 15 open issues, 35 open PRs and 222 commits. The releases section was not visible on fetch. FAQ: "timed out waiting for tmux session" errors are usually fixed by updating `claude`, which suggests it breaks when the agent CLI changes. The README describes no explicit needs-input indicator. — [GitHub](https://github.com/smtg-ai/claude-squad)
- Runs in "any tmux-friendly environment", meaning macOS and Linux. — [dev.to/Nimbalyst (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)

**ccmanager (kbwo/ccmanager)**
- Manages parallel sessions across git worktrees and projects for Claude Code, Gemini CLI, Codex, Cursor Agent, Copilot CLI, Cline, OpenCode, Kimi and others. It does not need tmux ("works out of the box"). It can create, merge and delete worktrees (also in the background), run post-create hooks, and copy gitignored files via `.worktreeinclude`. It also has devcontainer integration, presets, status hooks and experimental auto-approval. — [GitHub ccmanager](https://github.com/kbwo/ccmanager)
- Status per session: Waiting (needs input), Busy or Idle, with a configurable detection strategy per agent. MIT. Installs via npm. 783 commits, © 2026. The OS list isn't stated, but as a Node CLI it is presumably cross-platform. — [GitHub ccmanager](https://github.com/kbwo/ccmanager)

**dmux**
- A Node.js CLI on tmux with git worktrees and terminal panes. MIT, about 1.3k stars. — [amux blog (vendor)](https://amux.io/blog/best-multi-agent-orchestrators-2026/)

**amux (Mixpeek)**
- A Rust server with web dashboard, PWA and iOS app, using git worktrees, aimed at unattended 10 to 50 agents overnight with crash recovery. License is MIT + Commons Clause (not OSI open source). Self-hosting is free and amux Cloud starts at $39/mo. It calls itself a "newer project with a smaller community". — [amux blog (vendor-authored)](https://amux.io/blog/best-multi-agent-orchestrators-2026/)

**Conductor (Melty Labs, YC S24)**
- A Mac desktop app. Each agent gets its own git worktree, plus diff review, PR flow and checkpoints for rollback. It supports Claude Code, Codex, Cursor and OpenCode. It is free for now, with paid collaboration planned, and closed source. — [dev.to/Nimbalyst (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8); [amux blog](https://amux.io/blog/best-multi-agent-orchestrators-2026/)
- **macOS only. No Linux desktop client was found.** Cloud workspaces run in Linux sandboxes on Vercel and keep running after the app closes. An iPhone app for cloud workspaces is in TestFlight. It raised a $22M Series A in March 2026 (Spark, Matrix). — [devtune.ai](https://devtune.ai/verticals/coding-agent-orchestration/conductor.md); [runtimewire](https://runtimewire.com/article/conductor-iphone-app-cloud-coding-agents)
- One comparison says its sweet spot is 3 to 8 agents. — [search summary of comparison posts](https://munderdiffl.in/blog/best-claude-code-multi-agent-tools/)
- Original Show HN. — [HN 44594584](https://news.ycombinator.com/item?id=44594584)

**Nimbalyst (formerly Crystal)**
- Crystal is now Nimbalyst and no longer a separate product. Nimbalyst is a visual workspace with kanban boards, linked files and sessions, diff review, worktree integration, and an iOS companion for reviewing and resuming sessions. It runs on macOS, Windows, Linux and iOS. The desktop and iOS apps are MIT. It is free for individuals, with Teams pricing TBD. — [dev.to by Nimbalyst CEO (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8); [aiidelist](https://aiidelist.com/ide/nimbalyst.md)

**Vibe Kanban (bloop)**
- bloop announced its shutdown on 10 Apr 2026, saying most users were on the free plan and it had no business model. The project continues as open-source, community-maintained Apache-2.0 code, and the README carries a sunsetting notice. Remote services (issues, comments, projects, orgs) were removed after 30 days, but local workspaces still work. — [vibekanban.com blog](https://vibekanban.com/blog); [Nimbalyst blog (vendor)](https://nimbalyst.com/blog/vibe-kanban-after-bloop-whats-next/); [vibecoding.app review](https://vibecoding.app/blog/vibe-kanban-review)
- Community fork Alexi5000/vibe-kanban says it stands alone from v0.1.44 (Rust monorepo, MCP, Tauri desktop). It notes an unfixed upstream advisory on the `rsa 0.9.10` dependency as of 2026-10-20. — [GitHub Alexi5000/vibe-kanban](https://github.com/Alexi5000/vibe-kanban)
- It had about 26K stars at shutdown. — [X post](https://x.com/chenzeling4/status/2061704625666105366?lang=en)

**Sculptor (Imbue)**
- Runs parallel agents, each in its own Docker container. Changes merge in only after approval (Pairing Mode, merge review). It runs on macOS (Apple Silicon) and Linux. It is an early research preview, free for testers. — [dev.to/Nimbalyst (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8); [Show HN: Sculptor](https://news.ycombinator.com/item?id=45427697)

**Superset**
- An IDE-style desktop app, CLI and MCP server with git worktrees, diff review and automations. It runs on macOS, with a Linux CLI in beta. It is open source; free for one user, $15/user/month for Pro. — [dev.to (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8); [Show HN Superset](https://news.ycombinator.com/item?id=46368739)

**Mux (Coder)**
- A desktop and browser app with local, worktree or SSH-backed workspaces and its own multi-model agent loop. It runs on macOS, Linux and browser. AGPL-3.0, free. — [dev.to (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)

**Paneflow**
- A GPU-rendered native terminal workspace where agents run as panes. It runs on macOS and Linux. MIT, free. — [dev.to (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)

**Opcode (formerly Claudia)**
- A desktop GUI for one main Claude Code session plus background agents. It runs on macOS and Linux. AGPL-3.0. **It is described as no longer actively developed.** — [dev.to (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)

**Terragon**
- A third-party directory describes it in the past tense, as "formerly known as Terragon Labs", a remote background-agent orchestrator for Claude Code and Codex in the cloud. It lists the last commit of terragon-oss as about 5 months ago, so it is **likely stale or sunset (unconfirmed)**. — [skillsindex.dev](https://skillsindex.dev/tools/terragon-labs-terragon-oss/)

**Warp**
- Has an Agent Management Panel with per-tab status icons and notifications when an agent is blocked on a permission or diff approval. It added support for third-party CLI agents (Claude Code, Codex, Gemini CLI, OpenCode) in April 2026. Oz, a cloud platform for running many agents, launched in February 2026. — [Warp docs](https://docs.warp.dev/guides/agent-workflows/running-multiple-agents-at-once-with-warp/); [Warp blog](https://www.warp.dev/blog/category/product); [linux.org repost of It's FOSS](https://www.linux.org/threads/its-foss-vibeops-folks-rejoice-warp-launches-oz-for-managing-ai-coding-agents-in-the-cloud.62447/)

**Cloud runners: Codex, Devin, Kilo Code, Goose**
- OpenAI Codex uses a cloud sandbox per task with a web dashboard, plus an open-source Rust CLI; $20 to $200/mo. Devin uses cloud VMs, is proprietary, and costs $20 to $500+/mo. Kilo Code has an Agent Manager for VS Code, JetBrains and CLI with worktrees. Goose (Apache 2.0, now under the Linux Foundation AAIF) has no built-in isolation. — [amux blog (vendor)](https://amux.io/blog/best-multi-agent-orchestrators-2026/)

**Others mentioned by users:** cmux, CAS (factory mode), Gas Town, Beads (an issue tracker for agents), plannotator, ChatML, Rover, a local merge queue, tmuxx (supervisor/worker with hooks), and the Deck VS Code extension (its own tmux server). — [HN 47218318](https://news.ycombinator.com/item?id=47218318); [HN merge queue](https://news.ycombinator.com/item?id=49104747); [HN ChatML](https://news.ycombinator.com/item?id=47303711); [pypi tmuxx](https://pypi.org/project/tmuxx); [VS Code Deck](https://marketplace.visualstudio.com/items?itemName=a9a4k.deck)

### Inferences
- A durable markdown task record per task is rare. agent-deck's conductor `task-log.md` is the closest. Most tools treat the session or worktree as the record, so the user's markdown task-file approach is not duplicated by most tools.
- A tool's status detection is either hook-based (reliable, needs per-agent integration) or output-parsing/polling (breaks when the agent's TUI changes). The Claude Squad FAQ about tmux timeouts after Claude updates fits the second risk.
- The Claude Code agent view now covers Needs-input status, background persistence, auto-worktree and fork natively. Thin wrappers whose main value was "show me which agent is waiting" lose much of their reason to exist for Claude-only users. Multi-agent-CLI support (Codex, Gemini) and tmux/nvim integration remain their differentiators.
- Thin wrappers include workmux, Claude Squad, ccmanager and dmux. Agent-deck sits in the middle, with conductor, MCP pooling and remote control. Opinionated platforms include Conductor, Nimbalyst, Vibe Kanban, Superset, Sculptor (containers), amux and Mux.

### Gaps
- Exact latest release dates for workmux, Claude Squad, ccmanager and agent-deck could not be read from the fetched pages (the releases sections were truncated or empty).
- Sculptor's current (late 2026) status: searches for 2026 Imbue Sculptor news returned nothing. It may still be a research preview, or it may be stale.
- Terragon's shutdown is unconfirmed by a primary source.
- Jules (Google), Cursor background/parallel agents and the Codex app's parallel features: no 2026 sources were fetched, so Linux support and pricing are not verified.
- uzi, cekanje: nothing was found or searched within budget. Their existence and status are unverified.
- Warp's Linux support for agent features was not confirmed in the fetched sources (Warp itself does ship on Linux, but no source was fetched for this).

## Which work on Linux (Ubuntu), not just macOS?

### Takeaway
Ubuntu-capable tools: workmux, agent-deck, Claude Squad, ccmanager, dmux, Nimbalyst, Sculptor, Mux, Paneflow, Opcode (stale), Vibe Kanban (community). Conductor is macOS-only (cloud aside). Superset's Linux support is a CLI in beta.

### Cited Findings
- agent-deck: macOS, Linux and WSL. — [GitHub](https://github.com/asheshgoplani/agent-deck)
- workmux: Homebrew for macOS/Linux, plus Cargo, Nix and binaries. — [GitHub](https://github.com/raine/workmux)
- Claude Squad: any tmux-friendly environment. — [dev.to](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)
- Nimbalyst: macOS, Windows, Linux. Sculptor: macOS (Apple Silicon) and Linux. Mux, Paneflow and Opcode: macOS and Linux. Superset: macOS, with a Linux CLI in beta. Conductor: macOS. — [dev.to (vendor)](https://dev.to/stravukarl/best-tools-for-managing-parallel-ai-coding-agents-in-2026-14l8)
- Conductor has no Linux client; Linux appears only in its cloud sandboxes. — [devtune.ai](https://devtune.ai/verticals/coding-agent-orchestration/conductor.md)
- Claude Code agent view: idle sessions on macOS or Linux stop if no supervisor reconnects within about a minute after the supervisor stops, which implies Linux support. — [Claude Code Docs](https://code.claude.com/docs/en/agent-view)

### Inferences
- For someone moving between a Mac and an Ubuntu work machine, a terminal-native tool installed through Homebrew, Cargo or Go (workmux, agent-deck) or a hand-built bash workbench gives identical behaviour on both. Electron/Tauri GUIs add per-platform variance.

### Gaps
- ccmanager's OS support is not stated explicitly. Linux support for Nimbalyst's Linux build (packages, distros) is not detailed.

## Thin wrappers vs opinionated platforms; keeping up with native Claude Code features

### Takeaway
Claude Code's agent view and background sessions (v2.1.139, May 2026) natively duplicate the status, persistence and auto-worktree features that wrappers offered. Wrappers still add multi-agent-CLI support, tmux integration and merge or cleanup commands. No source found explicitly evaluates which wrappers have integrated with agent view.

### Cited Findings
- Agent view auto-isolates background sessions in `.claude/worktrees/`, shows Needs input, and supports `/fork` and `/bg`. — [Claude Code Docs](https://code.claude.com/docs/en/agent-view)
- Background sessions were introduced in v2.0.60, and agent view came later. — [Terragon search summary / agent37](https://www.agent37.com/blog/claude-code-background-agent)
- workmux and agent-deck both advertise forking or continuing conversations into new worktrees. — [workmux](https://github.com/raine/workmux); [agent-deck](https://github.com/asheshgoplani/agent-deck)
- A user in the HN thread said none of the orchestrators they tried fit their needs and that they prefer a custom setup. Workflows built around one model version often become obsolete with the next. — [HN 47218318](https://news.ycombinator.com/item?id=47218318)

### Inferences
- Wrappers that run claude inside their own tmux sessions run in parallel to Claude's own supervisor. They may not see or manage `claude --bg` sessions, so a user can end up with two session rosters.

### Gaps
- No source confirmed whether any third-party tool reads or integrates with Claude's agent view or supervisor state.

## Common patterns and failure modes (HN/Reddit)

### Takeaway
Users repeatedly report the same failure modes. Merge conflicts and drift between parallel branches. High cognitive load past 2 to 3 agents. Quota exhaustion. RAM/CPU pressure from parallel builds and dev servers. Agents bypassing deny lists. Worktree edge cases (submodules, deleting the main worktree). Several experienced users say a few focused agents beat many.

### Cited Findings
- Running parallel instances causes conflicting edits and confused state, and drift ends in merge conflicts. Some suggest jj workspaces instead of git worktrees. — [HN search summary](https://news.ycombinator.com/item?id=45489884); [HN 47218318](https://news.ycombinator.com/item?id=47218318)
- Worktrees don't work with submodules. Removing the worktree that holds the parent repo breaks the others. — [HN threads via search](https://news.ycombinator.com/item?id=45489884)
- 10 to 15 worktree sessions makes context switching the hardest part, and one user compared it to "landing a plane all day". — [HN 47218318](https://news.ycombinator.com/item?id=47218318)
- 4 to 5 agents on an 8GB MacBook Air building and running dev servers forced restarts. — [HN search summary](https://news.ycombinator.com/item?id=46990733)
- Parallel Opus agents exhausted a Max plan in under an hour. Another user hit a $200 plan's weekly quota by day 3 to 4. — [HN 47218318](https://news.ycombinator.com/item?id=47218318)
- Agents bypassed deny lists via `unlink` or Python subprocess, and one deleted an important untracked directory. — [HN 47218318](https://news.ycombinator.com/item?id=47218318)
- 2 to 3 focused agents (backend, frontend, tests) are more reliable than 6 to 8. Vague specs produce code that is slower to debug than it saved. A PROJECT.md helps prevent scope creep. — [HN 47218318](https://news.ycombinator.com/item?id=47218318)
- Worktrees don't isolate the environment (ports, DBs, env), which is why container tools such as Sculptor exist. — [comparison posts via search](https://rustman.org/wiki/conductor-parallel-agents/)
- The Vibe Kanban shutdown is a cautionary case for VC-backed free tools. Remote features disappeared after 30 days. — [vibekanban.com blog](https://vibekanban.com/blog)

### Inferences
- The user's design (one markdown task file per task, explicit handoff) matches the spec-driven pattern in the HN thread (schipper.ai, "Parallel coding agents with tmux and Markdown specs"), whose author also rejected off-the-shelf orchestrators.

### Gaps
- Reddit (r/ClaudeAI, r/ChatGPTCoding) threads were not fetched within budget. The evidence is HN-heavy.

## Zellij vs tmux for agent workflows in 2026

### Takeaway
In 2026 tmux is still the default because Claude Code Agent Teams supports only tmux and most orchestrators (Claude Squad, agent-deck, workmux) target it. Zellij has better defaults and WebAssembly plugins but no notable agent-specific plugin was found. workmux is the main orchestrator listing a Zellij backend.

### Cited Findings
- Claude Code supports only tmux for Agent Teams (v2.1.32+), and there is a feature request for native Zellij. — [GitHub issue #31901](https://github.com/anthropics/claude-code/issues/31901); [claudeissues mirror](https://claudeissues.com/issue/31901-feature-request-native-zellij-support-as-alternative-to-tmux-for-agent-teams-and)
- Zellij has sensible defaults with no config, WebAssembly plugins, a built-in web server, and native Windows support since March 2026. tmux is stronger for remote and scripted work. Neither tracks agent state natively. Herdr, a newer agent-focused runtime, shows per-pane state (idle, working, blocked, done). — [flaviocopes Herdr vs tmux vs Zellij](https://flaviocopes.com/herdr-vs-tmux-zellij); [classmethod migration post](https://dev.classmethod.jp/en/articles/herdr-tmux-replacement/)
- The common tmux approach is a sidebar or status-bar segment fed by agent hooks. — [flaviocopes](https://flaviocopes.com/herdr-vs-tmux-zellij)
- workmux supports Zellij, Kitty and WezTerm as alternatives to tmux. — [GitHub workmux](https://github.com/raine/workmux)
- A Termdock comparison (vendor) discusses tmux limits for agents. — [termdock](https://termdock.com/en/blog/terminal-multiplexing-tmux-termdock-zellij)

### Inferences
- For a user with an existing bash tmux workbench and nvim, switching to Zellij gains little for agent work and loses Agent Teams compatibility and most orchestrator support.

### Gaps
- No dedicated 2026 Zellij agent-status plugin was identified. Herdr's licence, platforms and maturity were not verified.
