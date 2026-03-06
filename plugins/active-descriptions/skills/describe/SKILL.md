---
name: describe
description: >
  Collaborative jj change description workflow. Use when writing, drafting,
  or reviewing a jj change description, or when stale descriptions are
  flagged by the staleness hooks. Analyzes the diff and conversation
  history, then applies the description via jj describe.
user-invocable: true
allowed-tools:
  - Bash: jj diff*
  - Bash: jj log*
  - Bash: jj describe*
  - Bash: jj status*
  - Bash: jj show*
---

# Active Change Description Workflow

Write change descriptions as a **joint artifact**, co-authored by human and
agent. Each contributes what they're uniquely positioned to know, at the
moment when that knowledge is freshest.

Audience: **the next reader who lacks today's context** — whether human
investigator or AI agent bootstrapping into the codebase. Immediate
reviewers benefit too, but the durable value is in the historical record.
Tooling (changelogs, release-notes generators) is a secondary consumer;
serve it through structural consistency, not by writing for machines.

Format: [Conventional Commits](conventional-commits.md).
VCS reference: [jj cheatsheet](jj-cheatsheet.md).

## The commit checkpoint

The commit step is not just documentation. It is a natural pause for
reflection on the work itself. Legitimate outcomes include:

- A well-described change lands.
- "We're not done yet" — the description process reveals gaps.
- "This should be structured differently" — split, reorder, or rethink.
- "I want to take a different approach" — diverge with a new change.

Treat description-writing as a moment to evaluate the work, not just
record it.

## Stale description trigger

This plugin includes a Stop hook that blocks the session from ending when
changes have diverged from their description. When the stop hook fires,
treat each flagged change as a describe target:

1. Run `jj diff -r <change>` to get the full current diff.
2. Enter the standard workflow below (Phase 1–2) for that change.

Handle multiple flagged changes sequentially.

## Phase 1: Internal analysis

Before engaging the human, analyze internally:

- **The diff.** Ground truth. Run `jj diff` (or `jj diff -r <change>`) and
  account for everything that actually changed, not just what was intended.
  The description may not contradict or omit from the diff.
- **The conversation history.** The full decision trail — every directive,
  correction, and change of direction. This is a first-class input, not
  crumbs.
- **Mechanical analysis.** Type classification, scope detection, atomicity
  assessment, completeness checks (tests touched? docs updated? error
  paths handled?), what the code used to do vs. what it does now.

This gives you a rich but incomplete picture. The gaps are what the
human knows but never said aloud.

## Phase 2: Write and apply

Write the full description using everything available: the diff, the
conversation history, and your mechanical analysis. Apply it directly
via `jj describe`.

**Match depth to the change.** Not every commit warrants a lengthy body.
Reason about proportionality for each specific change in its specific
context rather than following fixed categories.

## What makes a good description

**Title:** The effect, not the implementation. What changed for the
user or system. The "how" goes in the body.

- BAD: `fix: add mutex to guard database handle`
- GOOD: `fix: prevent database corruption during simultaneous sign-ups`

**Body:** Inverted pyramid. Most important information first. The reader
should be able to stop at any depth and have gotten maximum value.

When a body warrants headings, use this canonical vocabulary so that
readers — human and automated — can navigate predictably. Format
headings as `## Heading` (Markdown ATX-style), never with underlines
or **bold** text as a heading substitute.

| Heading | Use when... |
|---|---|
| Motivation | The "why" isn't obvious from the title alone |
| Background | Context the reader needs but can't get from the diff |
| Approach | The "how" involves non-obvious design choices |
| Alternatives considered | Other approaches were seriously considered or attempted |
| Findings | Implementation revealed surprising behavior or constraints |
| Testing | Verification goes beyond "tests pass" |
| References | Issues, docs, related changes |

Not every description needs headings. Not every headed description needs
all of these. But when you reach for a heading, reach for one from this
table — don't invent synonyms. Consistency across the history makes the
entire commit log more navigable.

**Content to include** — a menu, not a checklist. Exercise judgment
about which items each specific change warrants:

- **Motivation.** The human's actual goal — the business or user outcome
  this change serves. Most important after the title. State it concretely
  enough that a future reader can evaluate whether a proposed follow-up
  change would conflict with or support this intent.
- **Decision provenance.** Which decisions were human directives vs. agent
  choices. A future reader needs to know what to question and who to ask
  before changing course.
- **Breaking changes.** What breaks and how to adapt.
- **Alternatives considered.** What was rejected and *specifically* why it
  failed or was inferior. When approaches were actually attempted, say so
  — "Tried X; it failed because Y" is more valuable than "Considered X."
  Include enough detail that a future reader can evaluate whether changed
  circumstances might invalidate the rejection.
- **Non-obvious findings and learnings.** Surprising behavior, constraints,
  corrected assumptions, or mental models that turned out to be wrong.
  Capture domain/tool/ecosystem knowledge discovered during implementation
  that future readers would otherwise have to rediscover independently.
  Include the specific constraint or behavior, not just its existence
  ("libfoo silently truncates inputs > 64KB" vs. "discovered a libfoo
  limitation"). Admitting what you didn't know is a feature, not a
  weakness.
- **Testing boundary.** What was verified (by the agent and by the human
  outside the session), how, and what wasn't tested. For changes that
  require manual verification, include concrete reproduction steps so the
  reviewer can exercise the behavior themselves.
- **External references.** Issue trackers, audit findings, related
  discussions — non-obvious ones the reader couldn't trivially find.
- **New dependencies.** Flag and justify.
- **Cross-references.** `Fixes #1234`, related changes. Summarize linked
  issues.
- **Searchable artifacts.** Error messages, component names, task IDs.
  Name the *pattern* (race condition, schema migration, cache
  invalidation) — not just the symptom. Categorical terms make the
  commit history searchable by problem class, not just by incident.

**Content to leave out:**

- What's obvious from the diff.
- Invariants that belong in code comments or automated checks.
- Ephemeral discussion that belongs in PR comments.
- Transient artifacts (preview URLs, expiring build links).
- Process narration — how you arrived at the solution (iterations,
  false starts, discussion arcs) vs. why the solution is what it is.
  Describe the final state and its rationale, not the session journey.

**Self-contained.** The next reader will have zero access to the original
conversation — whether they are a human investigator or a fresh agent
session. The description + diff must be sufficient on their own. The
commit log is the closest thing to persistent memory across sessions;
treat every description as a cache entry. If context would otherwise
live only in chat, PR comments, or the conversation history, it belongs
in the description.

**No noise.** Every sentence must survive: "Would this help someone
reading this at 2 AM while debugging production?" Say exactly what the
diff can't say; omit what the diff already says. Color and context that
wouldn't survive this filter can still be included — at the end, clearly
separated — so it doesn't bury actionable information.

**Prose quality.** Prefer active voice, strong verbs, and positive phrasing.
Cut every word that doesn't earn its place.
