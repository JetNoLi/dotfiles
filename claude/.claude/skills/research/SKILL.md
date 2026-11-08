---
name: research
description: Pick the right approach for a research question and run it. Routes exploring, comparing options, checking a direction, a best-practices pass, and evaluating a tool, repo or skill to the skill that fits, and runs the last two itself when no installed skill does. Use when Jet types /research, or asks which skill to use for some research.
---

# /research

Jet's research questions come in five types, and a different skill suits
each. This skill names the type, says which route it is taking, and then
takes it.

Arguments: `` (the question, or nothing to ask for one)

## 1. Name the type

| Type | Signals | Route |
|---|---|---|
| Explore | "what's out there", "how do people do X", no options yet | `anthropic-skills:deep-research` for a sourced report; `compound-engineering:ce-ideate` for ideas grounded in this project |
| Compare | there are named options, and the question is which one | `compound-engineering:ce-pov` with the options as an approach set; `compound-engineering:ce-bakeoff` when an option has to be built out before it can be judged |
| Check a direction | "is this sound", "are we missing anything", a plan or approach already chosen | `compound-engineering:ce-pov` for a position or a holistic take; `compound-engineering:ce-doc-review` when it's a written plan or spec |
| Best practices | a common problem, and the question is how it is usually handled | Section 3, here |
| Evaluate | a named tool, repo, plugin or skill, and the question is whether to adopt it | A skill or plugin: section 4, here. A product or library: `compound-engineering:ce-pov` (external adoption), then section 4's checks for anything it would install |

Say the type and the route in one line before starting, e.g. "This is a
compare: running ce-pov with the three options." If two types fit, pick the
narrower one. If the type isn't clear, ask one question in chat with the
likely types as options and a recommendation.

Size the effort to the question. deep-research starts subagents and costs
far more than a few searches, so use it only when Jet wants a report, not
a quick answer.

## 2. Hand off

For a routed type, invoke that skill with the question and whatever context
this conversation holds: options, constraints, what is already installed.
Its own instructions then take over.

## 3. Best-practices pass

1. Write the problem as a neutral phrase, without naming the current
   solution, so the searches find the field and not this repo.
2. Run 3–5 standard web searches, in one turn. Prefer official docs, the
   tool's own maintainers, and engineering write-ups with real systems behind
   them. Use extended search only when standard results are thin or out of
   date.
3. Read the two or three best pages (the `web-fetch` agent, or WebFetch).
   Don't rely on search snippets for anything you state as a practice.
4. A practice counts when two independent sources describe it. Note where
   sources disagree, and mark vendor content as vendor content.
5. Compare against what this repo or setup does now, citing file and line.

Output, in chat: each practice in one line with its sources, what Jet does
now, and the gap if there is one. End with a recommendation and its options,
pros and cons. No subagents, and no report file unless asked.

## 4. Vetting a skill, plugin or tool

Never install anything while vetting. Read before judging:

1. **Read all of it.** The SKILL.md, its references, and every script it
   runs. Registry listings and READMEs are claims, not the skill.
2. **What it runs and sends.** Commands, `curl` or other network calls,
   API keys it needs, Docker images (pinned or not), hosted services that
   receive code or config.
3. **What it writes, and where.** Repo folders it creates. JetNoLi/dotfiles
   is public, and in an employer repo anything a skill writes is employer
   content.
4. **Overlap.** Compare its description and triggers with what's installed:
   `~/.claude/skills/`, and the plugins under `~/.claude/plugins/`. Two
   skills that trigger on the same words fight each other. Every installed
   skill also adds its description to each session's context.
5. **Upkeep.** License, maintainers, last release, open issues. A
   one-maintainer beta is fine to adapt, riskier to adopt.

Verdict: **adopt** (install as is), **adapt** (borrow ideas into a skill of
Jet's own), or **skip**, with one line on why and the options' pros and
cons. Jet chooses; installing is a separate step he approves.

## Rules for every route

- State facts with their source. Mark what you couldn't verify, and say when
  a page failed to load.
- Employer details never go in JetNoLi/dotfiles.
- Inside a wb task, record a decision Jet makes with `wb decision`, and put
  long findings in the task record (`wb checkpoint`), not only in chat.
