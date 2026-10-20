# 01 — Task planning & resilient resumption

PERMANENT protocol for running heavy prompts in a way that survives interruptions
(usage limits, crashes, deliberate stops). The goal: NEVER lose more than a single
task of work, and resume without reconstructing anything by hand. The `/fw:plan` command
runs it: it reads this doc, then plans or resumes.

> Where `plans/` and `decisions/` stay clean templates — the framework's own
> repository — a heavy deliverable keeps its plan and its structural decision in its
> session note instead, and resumption looks for the plan in the most recent note: the
> framework's `CONTRIBUTING.md` says how.

## Principle

A prompt is not run "in one breath" hoping to reach the end. It is judged, and if it
is heavy it is turned into a PLAN of small, atomic tasks, each of which ends with a
commit. The per-task commit is the checkpoint: if the session dies at task N, tasks
1..N-1 are safe on the branch and you resume from task N. Nothing is thrown away
except the interrupted half-done task.

## PHASE 1 — Assessment (always, before writing code)

At the start of EVERY prompt, before touching files, estimate the heaviness:
- How many files/modules/units/tests it will produce (order of magnitude).
- If it goes beyond roughly ~8-10 files or ~400 lines in total, or it touches several
  layers (e.g. logic + persistence + interface + tests), it is HEAVY → go to PHASE 2.
- If it is small and self-contained (a fix, an endpoint, a config change) → run it
  directly with a single final commit, no plan. Do not bureaucratise small tasks: the
  plan is a tool, not a ritual. If it goes to integration on its own, it is still a
  deliverable, closed with the cycle of `00-overview.md`: no plan is no exemption from it.

You make this assessment YOURSELF, without asking the user.

## PHASE 2 — Producing the plan

**Before the plan, if there are structural choices.** If the prompt involves
decisions that are expensive to reverse (architecture, contracts between modules,
the choice of an approach), the plan is NOT the first artifact: first a READ-ONLY
assessment of the real state, then the proposal with the alternatives and the
trade-offs, then the user's DECISION, recorded in `decisions/` (or as an ADR — see
the README of `decisions/`). Only then the plan, which POINTS at the recorded
decision instead of re-litigating it at every task. For prompts that are heavy but
have no structural forks, go straight to the plan.

Create `.claude/memory/plans/<prompt-id>.md` (e.g. `plans/03-module-x.md`) with this
format (frontmatter + checklist):

```markdown
---
type: plan
prompt: <prompt-id>
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
<empty at the start; here you record state/decisions useful to a future session>

## Links
[[<component>]] · [[STATE]]
```

Rules for the tasks:
- Every task must be ATOMIC and COMMITTABLE: it must leave the project in a
  consistent state (it builds / it is no worse than before). Good, stack-agnostic
  examples: "module scaffold + dependency manifest", "schema migration + data model",
  "implement <unit of logic> + tests", "endpoint/handler + DTO + validation". A bad
  example: "half of the security configuration".
- Order by dependency: what sits underneath before what sits on top of it.
- 6-12 tasks is the healthy range. More than ~15 → the prompt should have been split
  upstream (flag it as an IMP, see `06-self-improvement.md`). Fewer than 4 → it was
  not heavy, the plan was not needed.
- Once the plan is written, COMMIT IT immediately (`chore: plan for <prompt>`) before
  starting the tasks: that way the plan survives even an immediate crash.

## PHASE 3 — Task-by-task execution

For each task in order:
1. Implement it (commented code + handled errors, see `02-code-quality.md`).
2. Minimal verification that the task holds (it builds / the task's tests are green).
3. Commit with a message that references the task:
   `<type>(<scope>): [task N/T] <description>`
4. Tick the task in the plan: `- [x] N. ... — commit: <sha>` and commit the plan
   update together with it or right after (it may live in the same commit).
5. Move on to the next one.

Do NOT merge several tasks into one commit: it defeats the granularity of the
resumption.

## PHASE 4 — Completion

When all the tasks are ticked:
- `status: completed` in the plan's frontmatter.
- A full `/fw:checkpoint` (memory, docs, `STATE.md`: prompt done, next one).
- The merge onto the integration branch and the push are handled by the user, never
  an autonomous push (see `04-git-workflow.md`).

## Special case — cross-module refactor (shared code)

Extracting or moving code used by several modules (a common utility, a shared type,
an internal library) is a refactor with disproportionate risk: a single "green"
module says nothing about the other consumers. Treat it as a heavy prompt (PHASE 2 →
plan), and apply this additional discipline:

- **Dedicated branch, atomic tasks per consumer.** One step = one coherent,
  committable extraction: "introduce the shared module", then "migrate consumer A",
  then "migrate consumer B". Never "move everything" in a single task.
- **Tests of ALL touched modules green at EVERY step** — not only of the module you
  are working in, and not only at the end. After each task re-run the suites of every
  module that consumes the moved code: a regression introduced at step 2 is found at
  step 2, not three tasks later, when the cause is already buried.
- **A safety commit before starting** (docs/04, "WHEN to commit"): a wide refactor
  starts from a clean restore point.
- **A coherence review before the merge.** On top of the Definition of Done (docs/02)
  and — if it touches sensitive components — the security gate (docs/03), check that
  the extraction is coherent everywhere: no consumer left on the old copy, no
  leftover duplication, the shared API used the same way everywhere.
  **The shared contract can be TEXTUAL, not only code**: section titles cited BY NAME
  from other files are an API as well. If the work renames them (a translation, a wide
  documentation restructuring), grep the OLD and the NEW wording before the merge —
  having flagged the risk while planning is not a check (it happened: it was flagged, and
  the broken cross-reference passed anyway).

> The "wiring" between modules is exactly what isolated unit tests do not see: for a
> cross-module refactor the smoke test of the wired system (DoD, docs/02 point 3)
> matters even more.

## RESUMPTION (at the start of EVERY session, and after a pause inside one)

The `SessionStart` hook injects `STATE.md`. In addition, at startup — and when the same
session goes on after a pause (a usage limit, a machine's sleep) —:
1. Check whether a plan with `status: in-progress` exists in `.claude/memory/plans/`.
2. If there is one AND it concerns the prompt the user is asking for (or the user
   says "resume"): read the plan, run `git log --oneline` on the branch to confirm
   which tasks are already committed, and RESUME from the first unticked task. Do NOT
   restart tasks already done. Do NOT recreate the branch.
3. Verify before continuing, with or without a plan, scaled to what is not committed.
   Always: `git status`; the plan's ticks against the commits — a tick can lag its commit;
   and the branch's BASE: `git log --oneline origin/<integration branch>..HEAD` (without a
   remote, the local branch) lists only this deliverable's commits — one that is not means
   the branch started from the wrong base, clean tree or not. With work not yet committed, also: the build or syntax check, the
   tests of the area it touches, and its diff read against the plan or the recorded
   decision — the wiring gaps green tests miss show there.
4. Then the uncommitted work — the half-done task, or anything else: an edit of the user's
   between two sessions looks the same. In the same session after a pause the context holds:
   keep the work and go on if step 3 holds. In a new session its context is gone, and in
   either session step 3 may fail: then SHOW it — `git status --untracked-files=all` and
   `git diff` —, keep it while in doubt, and leave the discard to the user, who sees it
   first: `make reset-task`, which shows the same and asks, from their own terminal — never
   run by the agent with `YES`, given on the command line or exported, since make reads it
   from the environment too and any non-empty value skips the question —, or by hand, from
   the repository's top level (`git restore --source=HEAD --staged --worktree -- . && git
   clean -fd`; the agent's `deny` rules refuse `git clean`). Then restart from the clean
   task, not from rubble. A `chore: wip` commit (`04-git-workflow.md`, *WHEN to commit*) is
   half-done work too: step 3 verifies it, and it is never undone without the user
   (*Rollback*).
5. A well-formed resumption prompt gives the TASK directly ("resume from the first
   unticked task of plan X") and POINTS at the plan and the session notes for
   context: it must not produce an empty turn ("awaiting instructions") nor
   reconstruct in the chat what is already on disk.

## Cleanup of an interrupted task — SURGICAL, never destructive

If a session dies halfway through a task:
- ONLY the UNCOMMITTED work (the half-done task) is discarded, staged or not, and only by
  the user once they have seen it (*RESUMPTION*, step 4), from the repository's top level:
  `git restore --source=HEAD --staged --worktree -- .` — the index and the working tree
  from HEAD in one step: `git restore .` alone takes the tree from the index, so a staged
  change survives it — then `git clean -fd`.
- The branch is NOT deleted. The commits of previous tasks are NOT touched.
- `make reset-task` (the `scripts/reset-task.sh` script, with the project's protected
  branches from the `Makefile`) does exactly this, with a safety guard (it refuses to
  operate on shared branches): it shows the work, asks — `YES=1` skips the question, the
  user's form, never the agent's —, and says the task is discarded only when the tree then
  reads clean. Its limits: a merge, rebase or cherry-pick in progress keeps its state
  through the restore, and on a detached HEAD the guard has no branch to compare —
  settle those by hand first.
- Then the prompt is relaunched: the resumption protocol restarts from the right task.
