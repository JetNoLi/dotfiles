# Notifications, remote attention and implicit checkpoints for parallel Claude Code agents (as of Oct 2026)

## What notification mechanisms exist (push services, desktop, terminal, tmux), and how do they compare on setup, cross-platform support, privacy and noise?

### Takeaway
There are four layers, and most practitioners stack two or three of them:
1. Claude Code's built-in terminal notification. It works out of the box in Ghostty, Kitty and iTerm2, and through tmux once `allow-passthrough` is on.
2. A Notification/Stop hook that runs `osascript`/`terminal-notifier` on macOS or `notify-send` on Linux.
3. A persistent tmux status-bar indicator that clears when you focus the pane.
4. A phone push (ntfy, a chat bot, or the official Remote Control push).

Click-to-focus on GNOME Wayland is still the weak spot. Privacy depends almost entirely on which payload fields you choose to forward. `last_assistant_message` can contain code or secrets.

### Cited Findings
**Built-in terminal notifications**
- Claude Code sends a desktop notification by default only in Ghostty, Kitty and iTerm2. Other terminals can set `"preferredNotifChannel": "terminal_bell"` or use a Notification hook. Hooks run alongside the built-in notification and don't replace it — [Claude Code terminal config](https://code.claude.com/docs/en/terminal-config)
- The desktop notification reaches your local machine over SSH. Ghostty and Kitty forward it to the OS notification center without setup. iTerm2 needs "Notification Center Alerts" turned on, plus "Send escape sequence-generated alerts" under Filter Alerts — [terminal config](https://code.claude.com/docs/en/terminal-config)
- Inside tmux, notifications never reach the outer terminal unless `~/.tmux.conf` has `set -g allow-passthrough on` and `set -g focus-events on` (plus the extended-keys lines for Shift+Enter) — [terminal config](https://code.claude.com/docs/en/terminal-config)
- New: Claude Code v2.1.295+ reports per-session status (working / waiting / done) through the OSC 7501 "Program Status Protocol" to terminals that implement it. It does not work inside tmux, because Claude checks tmux rather than the outer terminal. Background sessions don't report it either — [terminal config](https://code.claude.com/docs/en/terminal-config)

**Terminal escape sequences (OSC 9 / 777 / 99)**
- OSC 9 is the iTerm2 style, where the payload is the notification text. OSC 777 (title + body) came from rxvt-unicode and was adopted by Ghostty and WezTerm. OSC 99 is Kitty's extensible protocol with urgency levels — [pi-notify](https://github.com/ferologics/pi-notify), [par-term notifications doc](https://docs.rs/crate/par-term/latest/source/docs/features/NOTIFICATIONS.md)
- GNOME Terminal / VTE is contested. A tcell issue says VTE "swallows" OSC 9/777, while a library page claims VTE terminals support OSC 777 — [tcell issue #499](https://github-redirect.dependabot.com/gdamore/tcell/issues/499); contradicted by [soloterm/notify](https://root.packagist.org/packages/soloterm/notify)

**Desktop notifications from hooks (macOS and Linux)**
- Official hook examples: macOS uses `osascript -e 'display notification "..." with title "Claude Code"'`, and Linux uses `notify-send 'Claude Code' '...'` — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- Gotcha: `osascript` notifications go through Script Editor. If Script Editor lacks notification permission, the call fails silently and macOS never prompts — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- `notify-send` needs a notification daemon. Headless servers, SSH sessions and most containers don't have one — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)

**GNOME Wayland and click-to-focus**
- claude-tmux-hop says click-to-focus isn't supported on Linux, and that its focus detection relies on X11 tools that don't work on Wayland — [claude-tmux-hop (PyPI)](https://pypi.org/project/claude-tmux-hop/)
- pi-desktop-notify implements Wayland click-to-focus only through niri, sway and Hyprland commands. It has no GNOME entry — [pi-desktop-notify README](https://cdn.jsdelivr.net/npm/pi-desktop-notify@1.0.1/README.md)
- A libnotify-style tool (`fyi`) documents that `--action` implies `--wait` and prints the triggered action name. This is the building block for "click → run tmux switch-client" — [fyi(1) man page](https://man.archlinux.org/man/fyi.1.en)

**ntfy**
- On public ntfy.sh, topics are public by default, so the topic name effectively works as a password. The guidance is to use a long random name. Topic names and IPs are logged on the public server — [ntfy privacy policy](https://docs.ntfy.sh/privacy/), [Hermes ntfy docs](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/ntfy)
- ntfy.sh offers access tokens (`tk_` prefix) on free accounts. Reserved topics and ACLs are on paid tiers — [Hermes ntfy docs](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/ntfy)

**Self-hosted ntfy**
- Supports `auth-default-access: deny-all` (recommended for private instances), per-user, per-topic ACLs with wildcards, and tokens (`tk_` + 32 chars, up to 60 per user). Tokens grant full account access and have no granular scopes — [ntfy config docs](https://docs.ntfy.sh/config/)
- Messages are cached in memory for 12h by default (`cache-duration`) and lost on restart unless `cache-file` is set — [ntfy config docs](https://docs.ntfy.sh/config/)
- iOS push on a self-hosted server uses `upstream-base-url`. Only a poll request goes to the upstream server: the message ID plus a SHA256 of the topic URL, with the body "New message". The app then fetches the real content from your server — [ntfy config docs](https://docs.ntfy.sh/config/)
- ntfy documents TLS only, with no end-to-end encryption on the config page — [ntfy config docs](https://docs.ntfy.sh/config/)

**ntfy publishing features**
- Publishing is a plain `curl -d` with headers: `Title`, `Priority` (1–5), `Tags` (emoji shortcodes), `Click` (a URL opened on tap), and `Actions` (up to 3 buttons of type `view`, `http`, `broadcast` or `copy`). An `http` action can send a POST with custom headers such as a Bearer token. In principle, that lets a phone button call back into a local or self-hosted endpoint — [ntfy publish docs](https://docs.ntfy.sh/publish/)

**Example: noise-thresholded ntfy hook**
- A public gist sends an ntfy push on Stop only when the session ran longer than 30 seconds. It records a start timestamp on SessionStart and includes project dir and git branch. It has no tmux awareness — [iboss-ptk gist](https://gist.github.com/iboss-ptk/3c036277237f4e483447a9f450244e58)

**Telegram / Discord / iMessage bots**
- These are official "Channels" plugins (research preview, needs Bun). They pair your account and then lock to an allowlist. Bot tokens are stored in `~/.claude/channels/<name>/.env` — [Channels docs](https://code.claude.com/docs/en/channels)
- Channels can be two-way. A channel that declares the "permission relay" capability can forward permission prompts so you approve or deny them from the chat. Anyone on the allowlist can then approve tool use — [Channels docs](https://code.claude.com/docs/en/channels)
- The iMessage channel is macOS-only. It reads `~/Library/Messages/chat.db` (Full Disk Access) and uses no external service — [Channels docs](https://code.claude.com/docs/en/channels)
- Slack/Discord/Telegram webhooks are also built into claude-notifications-go (below) — [claude-notifications-go](https://github.com/777genius/claude-notifications-go)

### Inferences
**Least-effort cross-platform baseline**
- Run Ghostty on both macOS and Ubuntu, with the built-in notification and tmux passthrough. Ghostty is in the "works by default" set on both OSes. It avoids the VTE/OSC uncertainty of GNOME Terminal and needs no hooks. The cost: tmux sessions lose OSC 7501 status.

**Privacy rules of thumb**
- Desktop notifications keep everything local.
- For phone pushes, send only the project/session name and event type, never `last_assistant_message` or `message`.
- Prefer self-hosted ntfy with deny-all ACLs, or a long random topic plus a token on ntfy.sh.
- Remote Control and Channels route content through Anthropic or the chat provider, respectively.

**GNOME Wayland**
- Plan on "notification + keyboard jump" (an fzf picker or tmux status) rather than click-to-focus. No source showed working click-to-focus on GNOME Wayland.

### Gaps
- **Pushover and Gotify:** I found no 2026 Claude Code-specific sources and did not fetch their docs. Their auth/privacy details are unverified here.
- **GNOME Terminal (VTE) and OSC 777:** unresolved. It needs a hands-on test.
- **OSC 7501 adoption:** I found no source listing which terminals implement it.
- **Mobile apps:** I did not verify whether ntfy's iOS app still needs the upstream poll workaround, beyond what the config docs say.

## What do Claude Code hook payloads (Notification, Stop, SessionEnd, PreCompact) provide, and can a notification identify and link back to the right session?

### Takeaway
Every hook gets `session_id`, `transcript_path` and `cwd`. Notification adds `message`, `title` and `notification_type`, and Stop adds `last_assistant_message`. The session name (`session_title`) appears only on SessionStart and UserPromptSubmit, and only when a custom title is set. To label a session you therefore cache the title or name by `session_id`, or use tmux `$TMUX_PANE`. HTTP hooks let a local daemon receive all events, and that daemon pattern is what cekanje uses.

### Cited Findings
**Common input fields**
- Every hook receives `session_id`, `prompt_id`, `transcript_path`, `cwd`, `scratchpad_dir`, `permission_mode`, `effort` and `hook_event_name`. Subagent hooks add `agent_id` and `agent_type` — [Hooks reference](https://code.claude.com/docs/en/hooks)

**Notification**
- Input: `message`, optional `title`, and `notification_type`. Example: `"message": "Claude needs your permission", "title": "Permission needed", "notification_type": "permission_prompt"`. The hook has no decision control — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Matcher values for `notification_type`:
  - `permission_prompt`, `idle_prompt`, `auth_success`
  - `elicitation_dialog`, `elicitation_url_dialog`, `elicitation_complete`, `elicitation_response`
  - `agent_needs_input`, `agent_completed` (agent view background sessions)
  - `quota_auto_resume_*`, `plugin_notification`

  — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Per the terminal docs, the notification event fires when Claude finishes or pauses for permission "and you appear to be away from the terminal". Claude Code therefore already applies its own presence gating — [terminal config](https://code.claude.com/docs/en/terminal-config)

**Session name / title**
- `session_title` appears in SessionStart and UserPromptSubmit input only when a custom title is set (`--name`, `/rename`, a hook's `sessionTitle` output, or the SDK's `renameSession()`). Generated titles are not included. Hooks can also set a title by returning `sessionTitle` from SessionStart or UserPromptSubmit — [Hooks reference](https://code.claude.com/docs/en/hooks)
- A March 2026 feature request asked for `session_name` in the Notification payload. It was marked "Fixed / completed" on 20 Mar 2026. However, the current docs I read list `session_title` only on SessionStart and UserPromptSubmit, not on Notification. Treat Notification as lacking it and verify on your version — [claudeissues.com #36623](https://claudeissues.com/issue/36623-feature-include-session-name-in-notification-hook-json); not reflected in [Hooks reference](https://code.claude.com/docs/en/hooks)

**Stop**
- Input: `stop_hook_active`, `last_assistant_message`, `background_tasks` and `session_crons`. The docs recommend `last_assistant_message` over reading `transcript_path`, because the transcript may not yet contain the final message at Stop time — [Hooks reference](https://code.claude.com/docs/en/hooks)
- `background_tasks` and `session_crons` let a hook tell "session is done" apart from "paused waiting for background work". This is useful for not notifying prematurely — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Stop doesn't fire on user interrupt. API errors fire `StopFailure`, whose `last_assistant_message` holds the error string, for example "API Error: Rate limit reached" — [Hooks reference](https://code.claude.com/docs/en/hooks)

**SessionEnd**
- Input: `reason` = `clear` | `resume` | `logout` | `prompt_input_exit` | `other`. The hook has no decision control — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Default timeout is only 1.5s. A per-hook `timeout` raises the budget up to 60s, or set `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`. Before v2.1.268 the env var did not change per-hook timeouts — [Hooks reference](https://code.claude.com/docs/en/hooks)

**PreCompact / PostCompact**
- PreCompact input: `trigger` (`manual` | `auto`) and `custom_instructions` (null for auto). Exit 2 blocks compaction — [Hooks reference](https://code.claude.com/docs/en/hooks)
- PostCompact input: `trigger` and `compact_summary`, which is the generated summary text. The hook has no decision control — [Hooks reference](https://code.claude.com/docs/en/hooks)

**Hook types**
- HTTP hooks (`"type": "http"`) POST the hook JSON to a `url`. Headers can interpolate env vars only if they are listed in `allowedEnvVars`. `onFailure` defaults to `continue`, and the default timeout is 600s on most events — [Hooks reference](https://code.claude.com/docs/en/hooks)
- `async: true` runs command hooks in the background. `asyncRewake: true` wakes Claude on exit 2 — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Prompt hooks (`type: "prompt"`) and agent hooks (`type: "agent"`) send hook input to a Claude model, by default the "background functionality" model. Agent hooks have a 60s default timeout — [Hooks reference](https://code.claude.com/docs/en/hooks)

**Linking a notification back to the session**
- cekanje uses HTTP hooks that forward the `TMUX_PANE` and `TMUX` env vars as headers. Each `session_id` is bound to a pane, so the notification maps to an exact `tmux switch-client` / `select-pane` — [cekanje docs](https://docs.rs/cekanje/0.2.0)

### Inferences
**Recommended labelling pattern**
- On SessionStart, write `session_id → {session_title or cwd basename, git branch, $TMUX_PANE}` to a small state file. Notification/Stop hooks then look up that label. This avoids depending on a payload field that may not exist.

**Noise control from payload fields**
- Matchers on `notification_type`, so only `permission_prompt` goes to the phone.
- Duration thresholds via a SessionStart timestamp.
- `background_tasks` emptiness checks.
- Claude's own presence gating.

### Gaps
- I couldn't confirm whether the Notification payload in late-2026 builds actually carries `session_title`. The docs and the closed issue conflict.
- The exact `idle_prompt` timing (how long idle before it fires) wasn't in the sections I read.

## Can Claude Code Remote Control / the mobile app notify you and let you answer permission prompts from your phone? What are the limits?

### Takeaway
Yes. With Remote Control on, the Claude iOS or Android app gets push notifications for "actions required" (permission prompts and questions) and for proactive "Claude decides" events, and you can answer from the phone. It needs a Pro/Max/Team/Enterprise login (no API keys, no Bedrock/Vertex/gateway). Session content transits Anthropic. Without server mode it's one remote session per process. Pushes are not configurable per event.

### Cited Findings
**Requirements and how it works**
- Plans: Pro, Max, Team and Enterprise. API keys aren't supported. On Team and Enterprise, an Owner must enable it. It fails if `ANTHROPIC_BASE_URL` points to a gateway or proxy, or on Bedrock / Agent Platform / Foundry. HIPAA orgs have it off — [Remote Control docs](https://code.claude.com/docs/en/remote-control)
- Execution stays local. The local process makes outbound HTTPS only, with no inbound ports, and all traffic is routed through the Anthropic API over TLS — [Remote Control docs](https://code.claude.com/docs/en/remote-control)
- Modes:
  - `claude remote-control` (server mode). Supports `--spawn same-dir|worktree|session` and `--capacity` (default 32 concurrent sessions).
  - `claude --remote-control "Name"` or `/remote-control` (one interactive session).
  - `remoteControlAtStartup: true` to auto-register every interactive process.

  — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

**Push notifications**
- Enable them in `/config`. There are two toggles, "Push when Claude decides" and "Push when actions required" (permission prompts and questions). Beyond those, "there is no per-event configuration." You can also ask in-prompt, e.g. "notify me when the tests finish" — [Remote Control docs](https://code.claude.com/docs/en/remote-control)
- Noise control: pushes are skipped while you are typing in or focused on the connected terminal. Set `CLAUDE_CLIENT_PRESENCE_FILE` to a marker file, created on screen unlock and deleted on lock, to suppress pushes whenever you're at the machine — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

**Dialogs answered remotely**
- Permission prompts and `AskUserQuestion` stay open until answered.
- Other forwarded dialogs expire after 5 minutes by default (`dialogExpiry`, v2.1.224+).
- The Fable usage-credits consent prompt is not forwarded.

  — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

**Limits**
- Outside server mode it's one remote session per interactive process.
- The local process must stay running, so use tmux on remote boxes.
- After network trouble: interactive sessions retry HTTP 403 for up to 3 minutes, server mode exits after about 10 minutes of outage, and a heartbeat failure disconnects after about 30 minutes.
- Some commands are local-only, such as `/plugin` and `/resume`.

  — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

**Session names and security**
- Session names are set by `--name` or are auto-generated as `<hostname>-<adjective>-<noun>`, with a prefix configurable by `--remote-control-session-name-prefix`. Renaming on the phone also updates the local `claude --resume` title — [Remote Control docs](https://code.claude.com/docs/en/remote-control)
- Optional "Trusted Devices" requires device enrollment and a biometric step-up when the sign-in is more than 18h old. It's off by default; on Pro/Max you enable it yourself — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

**Related features**
- Dispatch (in the Desktop app) lets you message a task from your phone and spawn a Desktop session — [Remote Control docs](https://code.claude.com/docs/en/remote-control)

### Inferences
**When to use it**
- Remote Control is the lowest-effort "answer from phone" path for Jet's personal Max/Pro login on macOS.
- On the Ubuntu work machine it depends on whether the employer's org enables it, whether a gateway is in use, and the employer's data policy. If those block it, fall back to local-only notifications, or to self-hosted ntfy with content stripped.
- `CLAUDE_CLIENT_PRESENCE_FILE`, combined with a lock/unlock listener, is the cleanest acknowledge-on-presence mechanism available. It could also gate custom ntfy hooks by checking the same file.

### Gaps
- I didn't find independent practitioner reports (HN/Reddit) on how reliable Remote Control push is in late 2026.

## Which community tools exist (cekanje, CCN, claude-code-notify variants, Josh Morony's tmux indicator, others), and which are maintained?

### Takeaway
The most complete open designs are cekanje (Rust HTTP-hook daemon, tmux pane binding, fzf jump, focus-to-clear) and Josh Morony's tmux status-bar setup (macOS, persistent alerts retracted on focus). claude-notifications-go is the most popular cross-platform packaged notifier, with webhooks to Slack, Discord and Telegram. CCN variants are small and Linux/dunst-only. Officially, `claude agents` (agent view) now covers much of the "which session needs me" problem.

### Cited Findings
**cekanje 0.2.0 (released 2026-05-11)**
- `cek serve` runs an HTTP daemon on 127.0.0.1:8731 that receives Claude Code HTTP hooks and binds sessions to tmux panes.
- Notification/Stop marks a session Waiting only if its pane is unfocused, and a tmux `pane-focus-in` hook (`cek visit`) clears it.
- `cek menu` is an fzf popup that jumps to the pane, and `cek status` shows ⏳N for the status bar.
- Native notifications come via notify-rust. macOS is tested, and Linux works, with a bundled systemd user unit.
- On restart it rebuilds state from `~/.claude/projects/` transcripts.
- Needs tmux 3.2+/3.3+ and fzf.

— [cekanje docs.rs](https://docs.rs/cekanje/0.2.0)

**Josh Morony's setup (27 Jul 2026; macOS 15.6, Ghostty, tmux 3.6a)**
- The status-right line shows `●N` running, `👁M` seen/idle, `✋name` awaiting approval, and `✅name` done-unseen.
- Alerts fire only when the terminal isn't frontmost and are de-duplicated per session. A custom terminal-notifier bundle uses the "alert" style so alerts persist, and focusing the pane, resuming, or ending the session retracts them.
- Hooks: UserPromptSubmit/Pre/PostToolUse → running, Notification `permission_prompt` → permission, `idle_prompt` and Stop → done, SessionEnd → clear.

Lessons from his write-up:
- macOS hides notifications while the screen is mirrored or shared.
- The alert style can't be changed after first registration, so the bundle ID must change.
- Retraction must go through the same app that posted the alert.
- Use `set-hook -g`, not `-ga`.
- Raise `status-right-length`.
- Sessions outside tmux are invisible to discovery.
- "Working" detection scrapes the TUI footer text "esc to interrupt", which is fragile.

— [joshmorony.com](https://www.joshmorony.com/effectively-manage-attention-across-multiple-coding-agents/)

**claude-notifications-go (777genius)**
- About 817 stars and 115 forks. Runs on macOS, Linux and Windows.
- Click-to-focus and sounds for Claude and Codex, optional focus-aware delivery, delays and filters.
- Webhooks to Slack, Discord, Telegram, Lark and custom endpoints (no native ntfy).
- Alerts include project, git branch and session name.
- Release v1.40.0 is listed on newreleases.io.

— [GitHub](https://github.com/777genius/claude-notifications-go), [newreleases v1.40.0](https://newreleases.io/project/github/777genius/claude-notifications-go/release/v1.40.0)

**CCN (Luxxgit2k4 fork of bupd/ccn)**
- Linux-only (X11/Wayland), requires dunst, with a "Go to window" action that switches to the exact tmux pane.
- 0 stars, no releases, no visible commit dates, so I can't confirm maintenance.

— [Luxxgit2k4/ccn](https://github.com/Luxxgit2k4/ccn), [bupd/ccn](https://awesome.ecosyste.ms/projects/github.com%2Fbupd%2Fccn)

**Other variants**
- naoto0822/ccn is macOS-only and its click opens VS Code or Cursor — [rust-digger ccn](https://rust-digger.code-maven.com/crates/ccn)
- yuki-yano/macos-notify-mcp is macOS-only and focuses a tmux session, window or pane on click — [glama](https://glama.ai/mcp/servers/@yuki-yano/macos-notify-mcp)
- assokhi/claude-notify is a Node plugin for macOS, Windows and Linux with "best-effort" click-to-focus — [skillselion](https://skillselion.com/skills/assokhi/claude-notify/plugins/notify)
- claude-tmux-hop has no Linux click-to-focus, and its focus detection is X11-only — [PyPI](https://pypi.org/project/claude-tmux-hop/)
- Others: ccnudge — [GitHub](https://github.com/RonitSachdev/ccnudge); wyattjoh/claude-code-notification — [GitHub](https://github.com/wyattjoh/claude-code-notification)

**Official: agent view (`claude agents`, research preview)**
- Groups sessions as Needs input / Working / Completed / Failed / Stopped, with "Peek" (Space) to answer a question without attaching, and filters like `s:blocked`.
- `claude agents --json --all` exposes `state` (`working|blocked|done|failed|stopped`) for scripts and status bars. The docs say not to parse `~/.claude/jobs/`.
- While agent view is open, background sessions notify via the terminal channel and fire Notification hooks with `agent_needs_input` / `agent_completed`.

— [Agent view docs](https://code.claude.com/docs/en/agent-view)

### Inferences
**Maintenance and fit**
- Maintenance signals are best for cekanje (recent versioned releases, 2026) and claude-notifications-go (many stars, numbered releases).
- Josh Morony's setup is a blog recipe, not a maintained package.
- CCN forks look like personal projects.

**Status-bar options**
- A tmux status bar fed by `claude agents --json --all` is a stable alternative to TUI scraping, but it covers only background (agent view) sessions.
- For classic tmux-pane sessions, cekanje's HTTP-hook plus focus-hook design is the cleanest, and it is portable to Ubuntu.

### Gaps
- I couldn't obtain last-commit dates for claude-notifications-go, the CCN forks, or the smaller notifiers.
- I found no exactly-named "claude-code-notify" repo.

## Automatic handoff/checkpoint writers (Stop / PreCompact / SessionEnd) and end-of-day sweeps across many sessions — what exists and what are the lessons?

### Takeaway
I found no official automatic handoff writer. The ingredients are all in hooks:
- PostCompact's `compact_summary` is a free summary.
- Stop's `last_assistant_message` gives the final turn.
- A `SessionStart` hook with the `compact` matcher re-injects context.
- Prompt/agent hooks can call a cheap model.

Community tools are mostly explicit `/handoff` skills, with a few end-of-day "park" skills built for 3+ parallel sessions. SessionEnd's 1.5s default budget is the main trap for automatic writers.

### Cited Findings
**Official building blocks**
- PostCompact receives `compact_summary` (the generated conversation summary). PreCompact receives `trigger` and `custom_instructions` and can block compaction with exit 2 — [Hooks reference](https://code.claude.com/docs/en/hooks)
- The official guide shows a `SessionStart` hook with matcher `compact` to "re-inject critical context after every compaction" — [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- Prompt and agent hook types send hook input (`$ARGUMENTS`) to a Claude model, by default the background-functionality model, or a `model` you specify. That is the official way to have a cheap model summarise or judge at Stop — [Hooks reference](https://code.claude.com/docs/en/hooks)
- SessionEnd timing: 1.5s default budget, raisable to 60s via a per-hook `timeout`, or via `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` — [Hooks reference](https://code.claude.com/docs/en/hooks)
- Async: `async: true` lets a command hook run in the background without blocking — [Hooks reference](https://code.claude.com/docs/en/hooks)

**History**
- A March 2026 request for PreCompact/PostCompact hooks, explicitly to run a handoff/summary command, was resolved — [claudeissues #30945](https://claudeissues.com/issue/30945-feature-request-precompact-postcompact-hooks)
- An open-ish GitHub request proposes a built-in `.claude/handoff.md` that is written at session end, read at the next start, and archived by date. It notes sessions are stateless by default — [anthropics/claude-code #11455](https://github.com/anthropics/claude-code/issues/11455)

**Community handoff tools**
- **cc-handoff:** `/handoff` writes a narrative doc, and a SessionStart hook flags pending handoffs. It is inspired by Steve Yegge's "anti-clonking" notes-to-next-session idea — [rhuss/cc-handoff](https://github.com/rhuss/cc-handoff)
- **claude-handoff (392fyc):** explicit-only. It writes a self-contained start prompt to auto-memory and can open a new terminal with it, for context limits and end of day — [392fyc/claude-handoff](https://github.com/392fyc/claude-handoff)
- **night-park skill (fearovex):** built for 3+ parallel late-night sessions. It drafts a summary, saves it to disk, and prints the exact resume command with the session ID, because "tomorrow it's impossible to remember which session was attacking which problem." There's a sibling session-handoff skill — [night-park](https://www.skills.sh/fearovex/claude-config/night-park), [session-handoff](https://www.skills.sh/fearovex/claude-config/session-handoff)
- **pro-workflow wrap-up:** triggered by "done for the day". It audits changes, runs quality checks, captures learnings and produces a session summary — [rohitg00/pro-workflow](https://www.skills.sh/rohitg00/pro-workflow/agent-teams)
- **Other handoff skills:** [robertguss handoff](https://www.skills.sh/robertguss/claude-code-toolkit/handoff), [steveclarke handoff](https://skills.sh/steveclarke/dotfiles/handoff), [willseltzer/claude-handoff](https://skillselion.com/plugin/willseltzer/claude-handoff)

**Official cross-session sweep surfaces**
- `claude agents --json --all` gives the states of all background sessions.
- `claude logs <id|name>` prints recent output.
- `claude rm` keeps the transcript (resumable) and refuses to delete worktrees with uncommitted or unpushed work.
- Idle, unattached background sessions may be stopped after about 1h and resume from the saved conversation.

  — [Agent view docs](https://code.claude.com/docs/en/agent-view)

### Inferences
**A plausible "implicit checkpoint" stack**
- PostCompact: write `compact_summary` to `handoffs/<session_id>.md`. No extra model call is needed.
- Stop: an `async` command hook appends `last_assistant_message`, cwd, branch and `git status --short` to the same file. A cheap-model rewrite is optional and could be a prompt/agent hook, or a later batch job.
- SessionEnd: only a fast flush or marker, given the 1.5s default. Raise `timeout` if it must do more.
- SessionStart (`resume`/`compact`): re-inject the latest handoff.

**End-of-day sweep**
- Iterate `claude agents --json --all`, plus any per-session handoff files written by hooks for tmux sessions.
- List blocked/done/unpushed sessions.
- Have one cheap-model pass produce a single digest with resume commands (the night-park pattern of printing `claude --resume <id>`).

**Lessons from the sources**
- Key handoffs by session ID, not just project, when running parallel sessions.
- Explicit handoffs produce better narratives. Automatic ones are for not losing state.
- Don't rely on `transcript_path` at Stop time.

### Gaps
- I found no public example that automatically summarises with a cheap model on Stop/PreCompact and reports lessons on cost or quality. The community tools I found are mainly explicit `/handoff` skills.
- I found no HN/Reddit practitioner threads on end-of-day sweeps across many agents. The evidence is skills and plugin READMEs with small install counts.
- I didn't verify install counts or maintenance for the handoff skills.
