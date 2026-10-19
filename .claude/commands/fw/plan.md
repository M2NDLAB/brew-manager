---
description: Plan a heavy prompt in atomic tasks, one commit each, or resume an interrupted plan (docs/01). Use when a prompt is judged heavy or the user says resume. Not the built-in /plan mode
---
Plan, or resume, the work for: $ARGUMENTS
(if empty: the prompt in progress).

1. Read `.claude/docs/01-task-planning.md` whole: it holds the thresholds, the plan's format
   and the resumption protocol this command applies. If the context has been compacted
   since, read it again before the next step.
2. Look for a plan in progress: `status: in-progress` in `.claude/memory/plans/` — or, where
   `plans/` stays a clean template, in the most recent session note (the doc's first note).
   If one concerns this prompt, or the user says "resume": go to step 5.
3. Judge the heaviness yourself (PHASE 1), without asking. Not heavy: say so in one line and
   run the prompt directly, one final commit, no plan — if it goes to integration it still
   closes with the end-of-deliverable cycle (`docs/00`). Heavy with structural choices: the
   read-only assessment, the proposal with its alternatives, then STOP for the user's
   decision, recorded in `decisions/` before any plan (PHASE 2, first paragraph).
4. Write the plan (PHASE 2): on a branch of its own, never on the integration branch
   (`docs/04`); `.claude/memory/plans/<prompt-id>.md` in the doc's format, atomic tasks ordered
   by dependency, 6-12 of them; commit it at once (`chore: plan for <prompt>`, the file added
   by its path). Then PHASE 3, task by task: the task, its minimal verification, its commit
   `<type>(<scope>): [task N/T] <description>`, its tick with the sha — never two tasks in
   one commit.
5. Resume (*RESUMPTION*): read the plan; `git log --oneline` on its branch; verify — `git
   status`, the ticks against the commits, the branch's base; with uncommitted work, its
   build, its tests and its diff against the plan —; then the uncommitted work: in the same
   session after a pause keep it if the verification holds; in a new session, or when the
   verification fails, show it (`git status --untracked-files=all`, `git diff`) and keep it —
   only the user discards it, `make reset-task` from their own terminal, never the agent with
   `YES`. Resume from the first unticked task: never redo a ticked one, never recreate the
   branch.
6. When every task is ticked (PHASE 4): `status: completed`, then the end-of-deliverable
   cycle — the merge and the push stay the user's (`docs/04`).
