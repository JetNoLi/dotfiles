# Task trackers and durable memory for AI coding agents (as of Oct 2026)

Context: options that could replace a hand-built local store of ~360 markdown task files (frontmatter plus Plan / Handoffs / Decisions / Done / Follow-ups sections, parent/child families, per-task locks, a save/resume handoff log, a decision-capture shelf). Must work on macOS and Ubuntu. Research date: 2026-10-25. Many sources are from Jan to Jun 2026, so details may be 4 to 9 months stale, and they are flagged where it matters.

## beads (steveyegge/beads, now gastownhall/beads, `bd`): storage, `bd ready`, compaction, messaging, agent use, pain points

### Takeaway
beads reached v1.0 (around April 2026). It now stores data in **embedded Dolt**, a version-controlled SQL database, and syncs through Dolt refs on a git remote. Its feature set is the closest to the user's needs: dependency graph, hierarchical epics, `bd ready`, atomic claim, LLM "memory decay" compaction, message issues, AGENTS.md onboarding. It also draws the most complaints about weight, invasiveness, the Dolt backend and code quality. Lighter forks and clones have appeared because of this (beads_rust, ticket, beans, dingles, seeds).

### Cited Findings
- The repo now lives at `gastownhall/beads` (steveyegge/beads redirects there). It describes itself as "a memory upgrade for your coding agent" and a dependency-aware issue tracker — [GitHub gastownhall/beads](https://github.com/gastownhall/beads)
- **Storage:** Dolt, described as a "Version-controlled SQL database with cell-level merge, native branching, and built-in sync via Dolt remotes". Embedded mode is the default and keeps data in `.beads/embeddeddolt/`. Server mode connects to an external `dolt sql-server` for multiple concurrent writers. `.beads/issues.jsonl` is "an export for viewers and interchange, not the source of truth or a backup" — [GitHub README](https://github.com/gastownhall/beads)
- Storage history: originally a "classic" SQLite + JSONL design, which the beads_rust author froze in a fork because "Beads is moving toward Steve's GasTown direction" — [beads_rust README](https://github.com/Dicklesworthstone/beads_rust). In March 2026 the architecture "appears to be in flux between SQLite-first and Dolt-first modes" — [tekai.dev, 2026-04-03](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
- v1.0 timeline: a v0.62.0 discussion titled "The Road to 1.0" made embedded Dolt the gate for 1.0 — [GitHub discussion #2757](https://github.com/gastownhall/beads/discussions/2757). A third-party blog says v1.0.0 shipped on April 2 (2026) — [Beadbox blog](https://beadbox.app/en/blog/beads-v1-the-hard-way). v1.0.1 release notes are mostly Dolt and init fixes — [Release v1.0.1](https://github.com/gastownhall/beads/releases/tag/v1.0.1)
- In v1.0.1, issues are no longer written to JSONL files by default, though that mode remains available — [DoltHub blog, 2026-04-15](https://www.dolthub.com/blog/2026-04-15-common-beads-workflows/)
- Embedded mode takes an exclusive file lock, so bd is effectively single-writer. `bd sql` is not supported in embedded mode. The v1.0 upgrade broke Beadbox's tooling ("a rollback, a flock bug, and 6 hotfixes") — [Beadbox blog](https://beadbox.app/en/blog/beads-v1-the-hard-way)
- **Multi-machine sync:** `bd dolt push` / `bd dolt pull` against `refs/dolt/data` on a git remote. In `--stealth` mode "All core commands work with zero git calls" — [GitHub README](https://github.com/gastownhall/beads)
- **`bd ready`:** "List tasks with no open blockers". `bd update <id> --claim` atomically sets the assignee and moves the task to in-progress — [GitHub README](https://github.com/gastownhall/beads). `bd ready --json` returns only unblocked work, which uses fewer tokens than loading full plan documents — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
- **Dependencies/families:** `bd dep add` supports blocks, related and parent-child links. Graph links include `relates-to`, `duplicates`, `supersedes` and `replies-to`. Epics use hierarchical IDs (`bd-a3f8` epic, `bd-a3f8.1` task, `bd-a3f8.1.1` sub-task). Hash-based IDs avoid merge collisions — [GitHub README](https://github.com/gastownhall/beads); [ANU COMP4020 task-tracking page](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/)
- **Compaction / "memory decay":** "Semantic 'memory decay' summarizes old closed tasks to save context window" — [GitHub README](https://github.com/gastownhall/beads). `bd compact` uses an LLM to summarize closed issues. This is lossy: the reasoning behind past decisions can be dropped, and no independent evaluation exists — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
- **Messaging:** a `message` issue type with threading (`--thread`), an ephemeral lifecycle and mail delegation — [GitHub README](https://github.com/gastownhall/beads)
- **Memories:** an open issue reports that agents don't discover that `bd remember --key` can update existing memories. This implies a key/value memory feature exists — [search summary of GitHub issues](https://github.com/steveyegge/beads/issues) (not verified directly)
- **Agent integration:** `bd init` creates or updates `AGENTS.md` and installs Claude Code, Codex and Cursor integrations unless `--skip-agents`/`--stealth` is passed. `bd onboard` prints a manual snippet. `bd prime` gives agents workflow context. A `beads-mcp` PyPI package exists — [GitHub README](https://github.com/gastownhall/beads)
- Agents need explicit prompting to use `bd ready` and can forget beads mid-session — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
- **Install (macOS/Ubuntu):** `brew install beads`, `npm install -g @beads/bd`, an install script, or `go install` — [GitHub README](https://github.com/gastownhall/beads). The Dolt dependency needs CGO plus a C compiler and ICU4c on macOS, despite being marketed as a single Go binary — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
- **Maturity:** about 18.7k stars, 29 contributors and v0.59.0 as of March 2026. The creator reportedly built it in six days with Claude — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents). More than 11,400 commits on main — [GitHub](https://github.com/gastownhall/beads)
- **Pain points (practitioners):**
  - A HN commenter calls beads "240,000 lines of code" managing markdown in repos and says the code quality is poor — [HN 46669791](https://news.ycombinator.com/item?id=46669791)
  - Recurring merge conflicts, with the agent keeping one side rather than merging — [HN 46463757](https://news.ycombinator.com/item?id=46463757)
  - "The backend didn't really make sense": a background SQL DB is required, it is unclear how it syncs with git, and Dolt does constant background disk I/O while idle. The commenter replaced it with "dingles" (JSONL + git, no SQL, built in a day or two). Replies: "fine until the author added Dolt" and "overengineered". One dissenter says the redundancies cover edge cases where agents fail — [HN 47772311](https://news.ycombinator.com/item?id=47772311)
  - The beads daemon "kept syncing the wrong things", which led to the bash-only `ticket` replacement — [Show HN 46487580](https://news.ycombinator.com/item?id=46487580)
  - Users complain about global installs, git-hook interference and sync problems ("uninstallable malware" thread). This is a secondary write-up, so treat it with caution — [asksurf.ai](https://asksurf.ai/pulse/en/beads-backlash-highlights-tooling-friction)
  - Embedded Dolt fails in repo paths containing spaces on macOS (open issue) — [GitHub issues, via search summary](https://github.com/steveyegge/beads/issues)
  - Databases can be silently dropped after migrating from embedded to server mode (gastown #1319). Dolt is benchmarked about 26x slower than Postgres/MySQL in some cases (dolthub #6536) — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents)
  - In beads' favour: agents file unrelated problems they find as issues without losing the current task — [asksurf.ai summary of HN](https://asksurf.ai/pulse/en/beads-backlash-highlights-tooling-friction)
- **beads_rust (`br`)**: a Rust port that freezes the classic design. It uses SQLite (`.beads/beads.db`, a pure-Rust "FrankenSQLite" engine) plus a JSONL export. It has no daemon, no auto git commits or pushes, and installs no hooks automatically. Commands include `ready`, `blocked`, `dep tree/cycles`, `sync --flush-only`, `doctor`, `--json`, `robot-docs`, and `serve` (MCP, optional feature). Version 0.7.6, about 1.1k stars. Runs on macOS, Linux, and Windows via WSL/Scoop. Building from source needs a pinned Rust nightly. No outside code contributions accepted. No Linear/Jira sync (bd has it) — [beads_rust README](https://github.com/Dicklesworthstone/beads_rust)
- Migrating bd to br: export JSONL from bd first, keep the ID prefix, and replace `bd sync` with `br sync --flush-only` plus explicit git add/commit — [skills.sh](https://www.skills.sh/boshu2/agentops/bead-tracker-migration); [Smithery](https://smithery.ai/skills/dicklesworthstone/bd-to-br-migration)

### Inferences
- beads' model maps closely onto the user's store. Parent/child families map to hierarchical IDs, per-task locks to `--claim`, a "what's next" query to `bd ready`, and the decision shelf partly to `supersedes`/`relates-to` plus memories. Compaction is lossy, though, and would erode a Decisions section unless decisions are kept outside closed issues.
- After the move to Dolt, the data is no longer greppable markdown in the repo. Day to day it lives in a binary DB, and JSONL is only an export. That reverses the user's current "files you can read" property.
- Single-writer embedded mode makes parallel agents on one machine contend for the lock. Server mode fixes that but adds a running daemon.
- beads_rust is the conservative choice if the beads model is wanted without Dolt or the daemon. It has a single maintainer and a nightly toolchain, which is a bus-factor and maintenance risk.

### Gaps
- No primary source found for current `bd compact` flags or schedule, or for how messaging and "mail delegation" work in detail. Molecules/wisps are mentioned only as filter flags.
- Steve Yegge's own posts were not fetched ([Introducing Beads on Medium](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a) surfaced but was not read).
- No 2026 data on how many users have stayed on bd after v1.0.

## Backlog.md (MrLesk): markdown-in-repo model, MCP, kanban/web views

### Takeaway
Backlog.md is the closest drop-in for a markdown task store. Each task is a `.md` file in `backlog/` in the repo. It has dependencies, milestones, acceptance criteria and a Definition of Done, separate docs and decisions areas, archiving, a terminal kanban, a local web UI, JSON CLI output and an MCP server. It runs on macOS, Linux and Windows.

### Cited Findings
- Each task is a plain `.md` file in a project-local folder (`backlog/`, `.backlog/`, or a custom path in `backlog.config.yml`). IDs use a configurable prefix (`TASK-1` by default) — [GitHub MrLesk/Backlog.md](https://github.com/MrLesk/Backlog.md)
- Supports dependencies (task detail shows what it waits on and what waits on it), milestones, per-task acceptance criteria, and a project-wide Definition of Done checklist added to new tasks — [GitHub](https://github.com/MrLesk/Backlog.md)
- **Decisions/docs:** `decision list`, `draft list`, and docs stored in the backlog folder. `backlog search` covers tasks, docs and decisions — [GitHub](https://github.com/MrLesk/Backlog.md)
- **Archiving:** archived tasks leave the board but keep their IDs, records and dependency links, and become read-only. `task restore` brings them back. `task delete` permanently removes an archived task — [GitHub](https://github.com/MrLesk/Backlog.md)
- **Views:** `backlog board` (terminal kanban), `backlog board export` (markdown report), and `backlog browser` (local web server on 127.0.0.1 with drag-and-drop and real-time updates) — [GitHub](https://github.com/MrLesk/Backlog.md)
- **Agent interface:** read commands give stable JSON, and `task list --json --watch` streams updates. `backlog mcp start` runs an MCP server for Claude Code, Codex, Gemini CLI, Kiro and Cursor. It detects the project from client roots, or you can pin it with `BACKLOG_CWD`. Workflow guidance is served at `backlog://workflow/...`. `backlog init` can write CLI instructions into AGENTS.md (telling agents to run `backlog instructions overview`) or set up MCP — [GitHub](https://github.com/MrLesk/Backlog.md)
- **Platforms:** macOS, Linux and Windows via npm, Bun, Homebrew or Nix (the flake covers x86_64-linux, aarch64-linux and aarch64-darwin) — [GitHub](https://github.com/MrLesk/Backlog.md)
- Version: the demo GIF filename references v1.40. The README states no version — [GitHub](https://github.com/MrLesk/Backlog.md)
- Listed by an ANU agentic-coding course as an "easy to grep and version with the repo" option with MCP and kanban — [ANU COMP4020](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/)

### Inferences
- The file-per-task markdown model and in-repo git history make migrating from the user's 360 files mostly a frontmatter and section-mapping exercise. Free-form sections such as Handoffs or Follow-ups would probably have to live in the task body, since the README shows no first-class handoff log.
- Sync across machines is just git, and it inherits git merge semantics on markdown files.

### Gaps
- Frontmatter schema, subtask/parent support and any locking or claim mechanism were not in the README excerpt. Check the docs or `backlog instructions`.
- No practitioner pain-point reports for Backlog.md were found in this pass.

## Other options: Taskwarrior 3, GitHub Issues/Projects, Linear, Jira, plain markdown and spec-driven tools, Task Master, Claude Code tasks, notable others

### Takeaway
SaaS trackers (GitHub, Linear, Jira) now ship official MCP servers with parent/sub-issue support. GitHub also has issue-dependency tools. They give a strong human-visible record and free multi-machine sync, but no agent-native "ready" or compaction semantics. Spec-driven tools (Spec Kit, Kiro) produce per-feature `tasks.md` checklists, not a long-lived backlog. Claude Code's built-in Tasks are local JSON under `~/.claude/tasks/`, are scoped by list ID with no repo awareness, and do not sync. Taskwarrior 3 has solid sync but is a personal todo tool with no agent integration found. A wave of small flat-file beads alternatives (beans, ticket, Trekker, dingles, seeds) appeared in 2026.

### Cited Findings
**Taskwarrior 3.x**
- Since 3.0, tasks live in a local database that can corrupt under Syncthing/rsync, so file sync is unsupported. Supported sync goes through a TaskChampion sync server (self-hosted, multi-user HTTP, client-side encryption with a shared secret, server never sees plaintext) or cloud storage (GCP/AWS; the man pages disagree on which are supported) — [taskwarrior.org sync docs](https://taskwarrior.org/docs/sync/); [Arch man task-sync(5)](https://man.archlinux.org/man/extra/task/task-sync.5.en)
- The self-hosted sync server is poorly documented — [LWN](https://lwn.net/SubscriberLink/969904/e6d9c7bc4f45b262). It has no HTTP auth by design, only UUID allowlisting, so put it behind a reverse proxy — [Unraid listing](https://ca.unraid.net/de/apps/taskchampion-sync-server-0wrxsgr06ooe8f)

**GitHub Issues/Projects**
- The official GitHub MCP server's issues toolset has `issue_read` (get, comments, `get_sub_issues`, `get_parent`, labels), `issue_write` (with `parent_issue_number`), `sub_issue_write` (add/remove/reprioritize/replace_parent), `issue_dependency_read`/`issue_dependency_write`, `find_duplicate`, and list/search/comment tools. The projects toolset (`projects_get/list/write`, up to 50 item updates per call) is **not** in the default toolset and must be added with `--toolsets`. A remote server at `https://api.githubcopilot.com/mcp/` uses OAuth or a PAT. A local server runs via Docker or a Go binary — [github/github-mcp-server](https://github.com/github/github-mcp-server)

**Linear**
- The official remote MCP server is at `https://mcp.linear.app/mcp` (Streamable HTTP, SSE also supported) with OAuth 2.1 and Dynamic Client Registration — [Cequence docs](https://docs.aigateway.cequence.ai/docs/remote-mcp-servers/linear). A third-party guide says it has 25+ tools and that a 2026 change merged create and update into `save_issue` — [MCPBundles](https://docs.mcpbundles.com/blog/linear-mcp-server) (secondary)
- `linear-beads` (nikvdp) is a beads-like tool that uses Linear as the storage backend so a human can watch tasks there — [Show HN thread summary](https://news.ycombinator.com/item?id=46709872) (via search summary)

**Jira**
- The official Atlassian (Rovo) remote MCP server at mcp.atlassian.com (v2 endpoint) is added with `claude mcp add` over HTTP, then `/mcp` to sign in. It supports OAuth 2.1 or API tokens (tokens suit headless use), respects Jira permissions, and needs an Atlassian Cloud site — [atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server); [Atlassian Rovo MCP](https://www.atlassian.com/platform/rovo-mcp)

**Spec-driven tools**
- GitHub Spec Kit commands: `/speckit-constitution`, `-specify`, `-plan`, `-tasks`, `-implement` and `-converge` (repeat implement and converge until "Converged"). Bug and assess extensions exist. Installed via `uv tool install specify-cli`. Runs on Linux, macOS and Windows (Python 3.11+). It keeps state in `.specify/memory`, and news mentions "Spec Kit 1.0" — [github/spec-kit](https://github.com/github/spec-kit)
- Kiro: each spec in `.kiro/specs/` has `requirements.md` (EARS notation), `design.md` and `tasks.md`. The UI marks tasks in-progress or completed and runs independent tasks concurrently based on dependencies. Steering files go in `.kiro/steering/` — [kiro.dev specs docs](https://kiro.dev/docs/specs/index) (steering details are community-sourced)
- Spec toolkits (spec-kit, superpowers, cc-sdd, agent-os) emit tasks as one stage of a pipeline rather than as a standalone tracker — [ANU COMP4020](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/)

**Task Master (claude-task-master / task-master-ai)**
- An MCP server plus CLI that parses a PRD into `.taskmaster/tasks/tasks.json`. `next_task` picks tasks whose dependencies are all done and ranks them by priority, dependency count and ID. It also has `expand_task` — [ANU COMP4020](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/); [Task Master rules via Glama](https://glama.ai/mcp/servers/@eyaltoledano/claude-task-master/blob/f961235442aa88e4983b29ab458b6a476fadf370/.cursor/rules/architecture.mdc)
- Release 0.43.0 fixed data loss when several instances (for example, several Claude Code windows) write the same tasks.json concurrently. Latest found: 0.43.1, dated "31 Mar" with no year shown — [GitHub releases](https://github.com/eyaltoledano/claude-task-master/releases). Called "probably the most-installed" in this category in HN discussion — [HN via search](https://news.ycombinator.com/item?id=46709872)

**Claude Code built-in Tasks / agent teams**
- Tasks (around v2.1.16, Jan 2026): each session gets an isolated list that disappears when the session closes. Setting `CLAUDE_CODE_TASK_LIST_ID=<id>` persists the list to `~/.claude/tasks/<id>/` and shares it across sessions, with updates broadcast. Tasks can block other tasks. Lists are not repo-aware, so reusing an ID across repos mixes tasks. There is no MCP server or web UI, it works only with Claude Code and the Agent SDK, and the format may change. Anthropic reportedly took inspiration from beads — [paddo.dev, 2026-01-23](https://paddo.dev/blog/from-beads-to-tasks/)
- Agent teams (experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`): a shared task list with pending, in-progress and completed states. Dependencies auto-unblock. Claiming uses file locking. Hooks: `TaskCreated`, `TaskCompleted`, `TeammateIdle`. The task list lives at `~/.claude/tasks/{team-name}/` (team name `session-<8 chars of session id>`), stays after the session ends, and is cleaned up per `cleanupPeriodDays`. Mailboxes are JSON at `~/.claude/teams/{team}/inboxes/{agent}.json`. Limitations: one team per session, no sharing across sessions, no `/resume` of in-process teammates, and status can lag (teammates fail to mark tasks complete) — [Claude Code docs: agent teams](https://code.claude.com/docs/en/agent-teams.md)

**Notable lightweight alternatives (2026)**
- **beans** (hmans): markdown files in `.beans/` plus `.beans.yml`, both committed. `beans prime` outputs agent context, and Claude Code hooks run it at session start and before compaction. A GraphQL query engine returns only the needed fields. Completed beans are archived as queryable memory. Has `beans tui`. Installs via Homebrew, Releases or `go install`. "Under heavy development, APIs may change" — [GitHub hmans/beans](https://github.com/hmans/beans). Called "much less invasive than beads" — [HN 46709872 via search](https://news.ycombinator.com/item?id=46709872)
- **ticket** (wedow): a single bash script on coreutils over flat markdown files. Keeps graph dependencies and drops everything else. Built after the beads daemon "kept syncing the wrong things" — [Show HN 46487580](https://news.ycombinator.com/item?id=46487580)
- **Trekker** (obsfx): a minimal tracker with a Claude Code plugin and a lightweight dashboard — [HN via search](https://news.ycombinator.com/item?id=46709872)
- **dingles**: a JSONL + git tracker, no SQL, synced by normal merges or a dedicated ticket branch — [HN 47772311](https://news.ycombinator.com/item?id=47772311)
- **seeds** (Ryan Duryea, Jun 2026): a *deliberation* tracker (questions, alternatives, rationale) for agents. SQLite plus a JSONL export for git. Commands: `jot`, `ask`, `answer`, `explore`, `resolve`, `defer`, `abandon`, `link`, `tree`, `prime`. Resolve, defer and abandon require a reason. Built because plan files silently overwrote deliberation and ADRs capture decisions only after the fact — [jigsaw.io, 2026-06-10](https://jigsaw.io/tools/2026/06/10/introducing-seeds.html)
- **todo-mcp**: a generic project-scoped todo MCP server with persistent storage — [ANU COMP4020](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/)

### Inferences
- None of the SaaS options offers a native `ready` query that respects blockers. An agent would have to filter dependencies and sub-issues itself, or lean on GitHub's dependency tools. They do give history and comments (usable as a handoff log) for free.
- Claude Code Tasks are too ephemeral and tool-locked to replace a 360-task multi-month store. They could serve as the in-session execution layer on top of a durable store, as paddo frames it ("complementary layers").
- seeds directly targets the user's "decision-capture shelf", and pairs with an execution tracker rather than replacing one.
- Taskwarrior has the most mature cross-platform sync, but no agent conventions or MCP surfaced, and its data model has no Plan, Handoff or Decision sections.

### Gaps
- No primary source on whether `CLAUDE_CODE_TASK_LIST_ID` is still current as of Oct 2026. The official docs fetched cover only the agent-teams layout.
- No Taskwarrior MCP server or agent-workflow reports were searched or found.
- Jira and Linear sub-issue/dependency coverage in their MCP servers was not confirmed from primary docs.
- Plain TODO.md/PLAN.md conventions were not researched separately beyond the course page's "pick one tracker and keep it boring" advice.
- Task Master's 2026 version and maintenance status are unconfirmed.

## Patterns: append-only logs vs mutable status, derived status, backlog expiry

### Takeaway
Practitioners split *working memory* (mutable, rewritable agent tracker) from the *permanent record*, and treat lossy summarization of closed work as a deliberate expiry mechanism. Several 2026 tools exist because mutable plan files silently overwrite history. Append-only JSONL plus git, or Dolt's versioned SQL, are the two main ways to keep history while status stays mutable.

### Cited Findings
- "Separate agent memory from the permanent record": the agent tracker (beans, beads, Backlog.md) is working memory that can be rewritten freely, while a human-visible tracker (Linear, GitHub Issues) is the lasting record. Also: "Pick one tracker and keep it boring", and reconcile agent progress claims against the tracker rather than the conversation — [ANU COMP4020](https://comp.anu.edu.au/courses/comp4020-agentic-coding-studio/topics/task-tracking/)
- Plan files that the AI rewrites silently overwrite the deliberation behind them. ADRs capture only after-the-fact decisions. seeds requires a reason on every resolve, defer or abandon — [jigsaw.io seeds](https://jigsaw.io/tools/2026/06/10/introducing-seeds.html)
- beads' expiry is LLM summarization of old closed issues ("memory decay"), which is lossy for decision rationale — [tekai.dev](https://tekai.dev/references/2026-04-03-beads-graph-issue-tracker-ai-agents); [beads README](https://github.com/gastownhall/beads)
- Backlog.md's expiry is archiving: tasks leave the board but stay read-only with links intact — [Backlog.md](https://github.com/MrLesk/Backlog.md). beans archives completed work as queryable memory — [beans](https://github.com/hmans/beans)
- Derived status: Claude Code agent teams auto-unblock dependents when a blocker completes. Status can lag when an agent forgets to mark completion — [Claude Code docs](https://code.claude.com/docs/en/agent-teams.md). The beads ready set is computed from open blockers — [beads README](https://github.com/gastownhall/beads)
- Append-only JSONL + git as a simpler substitute for a DB: dingles (sync via merges or a ticket branch) — [HN 47772311](https://news.ycombinator.com/item?id=47772311); beads_rust keeps JSONL for git collaboration — [beads_rust](https://github.com/Dicklesworthstone/beads_rust)
- Session-start "prime" hooks (`beans prime`, `bd prime`) re-inject tracker context at session start and before compaction, so resuming doesn't depend on the agent remembering — [beans](https://github.com/hmans/beans); [beads README](https://github.com/gastownhall/beads)

### Inferences
- The user's Handoffs and Decisions sections are append-only by nature. Most trackers model mutable status well but treat history as either a comment stream (SaaS), a git log (markdown tools) or a lossy summary (beads). Keeping decisions in a separate, never-compacted store (seeds-like, or ADR files) avoids losing them to compaction.
- A "prime" hook is the main tool-agnostic pattern worth keeping regardless of which tracker is chosen.

### Gaps
- No source quantified how well any compaction or expiry scheme preserves useful context.

## Repo-local vs central store; keeping work and personal tasks separate

### Takeaway
Most agent-native tools (Backlog.md, beads/br, beans, ticket, Spec Kit, Kiro, Task Master) store tasks **in the repo they concern**, so work and personal projects separate naturally by repo. Cross-project views and syncing a work machine with a personal one then depend on each repo's git remote. Central stores (Claude Code Tasks in `~/.claude/tasks`, Taskwarrior, Linear, Jira, GitHub Projects) give one cross-repo view, but they mix contexts unless scoped deliberately by list ID, project or account.

### Cited Findings
- Repo-local: Backlog.md `backlog/` — [Backlog.md](https://github.com/MrLesk/Backlog.md). beans `.beans/` and `.beans.yml` committed — [beans](https://github.com/hmans/beans). beads `.beads/` with optional `--stealth` (no git calls) — [beads](https://github.com/gastownhall/beads). Task Master `.taskmaster/tasks/tasks.json` — [GitHub releases](https://github.com/eyaltoledano/claude-task-master/releases). Kiro `.kiro/specs/` — [kiro.dev](https://kiro.dev/docs/specs/index). Spec Kit `.specify/` — [spec-kit](https://github.com/github/spec-kit)
- Central: Claude Code Tasks in `~/.claude/tasks/<id>/`, not repo-aware. Reusing an ID across repos mixes tasks, so use repo-specific IDs — [paddo.dev](https://paddo.dev/blog/from-beads-to-tasks/). Agent-team task lists are also user-global under `~/.claude/tasks/` and cleaned up per `cleanupPeriodDays` — [Claude Code docs](https://code.claude.com/docs/en/agent-teams.md)
- beads can run in stealth mode with "zero git calls", so the tracker can sit in a repo without being committed to it, which suits work repos where adding tracker files may not be acceptable — [beads README](https://github.com/gastownhall/beads)
- Backlog.md lets you set a custom backlog path in `backlog.config.yml`, and the MCP server can be pinned with `BACKLOG_CWD` — [Backlog.md](https://github.com/MrLesk/Backlog.md). This would allow a store outside the code repo.
- The bd/br git-hook and auto-commit behaviour is a concern in shared repos. br deliberately does no automatic git operations — [beads_rust](https://github.com/Dicklesworthstone/beads_rust). Users complained about bd's git-hook interference — [asksurf.ai](https://asksurf.ai/pulse/en/beads-backlash-highlights-tooling-friction)

### Inferences
- For a user with a work Ubuntu machine and a personal Mac, repo-local storage keeps employer and personal tasks physically apart, with no shared SaaS account. Committing tracker directories into work repos may conflict with team norms. Stealth mode, a gitignored folder, or a separate "tasks" repo next to the code fixes this.
- One central private markdown repo (the user's current approach) remains a valid, low-risk design. Of the tools reviewed, Backlog.md with a custom path, or br, could slot into that model with the least change.
- Cross-platform: Backlog.md (npm/brew/nix), beads (brew/npm/go, with CGO caveats on macOS), br (brew/install script), beans (brew/go), ticket (bash) and Taskwarrior all claim macOS and Linux support. SaaS options are platform-neutral.

### Gaps
- No source discussed employer policy or data-governance implications of agent tracker files in work repos.
- No source compared performance of the tools at about 360+ tasks.
