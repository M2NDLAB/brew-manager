# plans/ — task plans for heavy prompts

One plan for every **heavy prompt**, according to the task planning protocol
(`.claude/docs/01-task-planning.md`). A big prompt is not executed "in one
breath": it is broken into **atomic tasks, each with its own commit**. The plan is
the checklist that makes execution **resilient to interruptions** — if the session
dies at task N, tasks 1..N-1 are safe on the branch and work resumes from task N,
without rebuilding anything by hand.

## When it is created
At the start of a prompt that Claude Code judges heavy (≈ more than 8-10 files, or
~400 lines, or touching several layers). Small tasks do NOT need a plan. The plan is
created and **committed immediately**, before starting the tasks, so it survives even
an immediate crash.

## Life cycle
`status: in-progress` during execution → `status: completed` when all the tasks
are ticked. At the start of every session, an `in-progress` plan signals where to
resume.

## Naming
`<id-prompt>.md` — e.g. `01-scaffold.md`, `03-modulo-x.md`.

## Format
```markdown
---
type: plan
prompt: <id-prompt>
branch: <dedicated feature branch>
created: YYYY-MM-DD
status: in-progress | completed
tags: [plan, <area>]
---
# Plan: <prompt>

## Goal
<1-2 lines: what must exist once the plan is complete>

## Tasks
- [ ] 1. <atomic task, committable on its own> — commit: —
- [ ] 2. <...> — commit: —
- [ ] 3. <...> — commit: —

## Resumption notes
<empty at the start; state and decisions useful to a future session go here>

## Links
[[<component>]] · [[STATE]]
```

Rules about tasks (summary — detail in `docs/01`): every task atomic and
committable, ordered by dependency, 6-12 tasks is the healthy range, one commit per
task with `[task N/T]` in the message, the task is ticked with its sha.

> This README stays as a guide; the plans live alongside it.
