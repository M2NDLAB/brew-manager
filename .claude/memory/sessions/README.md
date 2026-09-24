# sessions/ — working journal (append-only)

One note for every significant **working session**. It is the project's narrative
memory: *what was done, what went wrong and how it was solved, what was decided on
the fly*. Unlike `STATE.md` (which gets rewritten and is a dashboard of the
present), session notes are **append-only**: they are not modified after the fact,
they accumulate. They are the first line of defence against "why on earth did we do
it this way?" — and the best source of improvement proposals (see
`docs/06-self-improvement.md`).

## When to write one
At the end of a task/session, typically inside `/checkpoint`. An escalation
(`docs/05`) is recorded here too, with its ID. And ALWAYS before a `/clear` or a
model switch, if the chat holds expensive work not yet persisted (an assessment, a
review, decisions taken on the fly): the chat context is lost, the note is not —
and the next prompt will be able to POINT at the note instead of rebuilding it.

## Naming
`YYYY-MM-DD-<short-slug>.md` — e.g. `2026-06-14-setup-iniziale.md`,
`2026-06-15-modulo-pagamenti.md`. The leading date keeps the chronological order.

## Format
```markdown
---
date: YYYY-MM-DD
task: <what was being done>
branch: <git branch>
status: completed | in-progress | blocked
model: '<model id as the runtime exposes it>'
turns: <n>
tags: [session, <area>]
---
# Session YYYY-MM-DD — <title>

## Done
- <itemised list of what was produced, with the relevant commits/shas>

## Problems encountered → cause → solution
1. <symptom> → <root cause> → <fix>

## Factual doc corrections (Level 1, docs/06)
- <doc aligned to reality, if it happened>

## Proposals
- IMP-nnn (in LEARNINGS.md): <any improvement proposal that emerged>

## Follow-up
- <any open threads picked up at a later date>
```

## The `model` and `turns` fields

Two OPTIONAL frontmatter fields, written by the agent that writes the note:
which model produced it — so its reliability can be weighed after the fact — and how
many exchanges the recorded work took — an objective proxy of its friction.

- **Absent = not recorded.** Notes that predate the fields stay valid; never backfill
  them — the values would be reconstructed, not recorded. The fields are historical
  attributes of the note: for `/lint-memory` they are neither stale claims (check 3)
  nor concepts that call for a page of their own (check 5).
- **`model`** — the identifier of the model running the main session, **as the runtime
  exposes it to the agent**, verbatim. A free value, never an enum: model names change.
  ALWAYS in single quotes (a `'` inside the id is doubled): unquoted, an id can break the
  YAML (e.g. brackets inside a list) or be coerced into a number, a date or a boolean;
  double quotes would turn a `\` into an escape. Several models on the same note (a
  model switch, a resumption on another model): ONE string with the distinct ids in
  order of first use, separated by `, `. Not exposed by the runtime → omit the field,
  never guess. Delegated work is not covered: if substantive findings came from
  subagents on a different model, say so in the body. Different strings may denote the
  same model (e.g. a context-window suffix): no normalisation — compare by base id when
  aggregating.
- **`turns`** — a bare integer ≥ 1: the user's messages whose work THIS note records,
  counted from the conversation (not by parsing runtime logs, whose user-type entries
  may include tool results). Counted: prompts, commands that start work by the agent,
  answers to the agent's questions, feedback typed when rejecting an action. Not
  counted: commands handled locally that the agent does not answer (e.g. a model
  switch, `/clear`), automatic or system messages, approvals given with a click. It is
  **per note**: a unit of work recorded in several notes (resumptions, one note per
  session or day) is the SUM of its notes, computed when the data is analysed — e.g.
  per deliverable, grouped by `branch` — and never recorded. No quotes, `~`, `+` or
  leading zero: the approximation is declared here, not in the value.
- **A PROXY, not a measure.** It does not weigh long turns against short ones, and after
  a context compaction or a resumption it is a lower bound — still written: omitting it
  would drop exactly the high-friction cases.
- **When.** Both fields are refreshed at every write that records work. `turns` = the
  value the note carried BEFORE this session first wrote to it (0 for a new note) + all
  of this session's messages so far — so rewriting the note within one session never
  counts a message twice. If one session closes several notes, each counts from the
  first message after the previous note was last written. A later session that records
  NEW work in the same note (today's note written again, an escalation resolved) adds
  its own messages the same way. Edits that record no new work (a link repair, a
  translation) never touch the fields, and nothing after the checkpoint that completes
  the work is counted (e.g. the integration).
- **Written by the main session.** If a delegated agent writes the note, it records the
  values the main session passes to it — never its own prompts or its own model.
- **Recorded data only**: no command consumes these fields; a threshold rule on `turns`
  is a separate, deferred proposal.

> This README stays as a guide; the session notes live alongside it.
