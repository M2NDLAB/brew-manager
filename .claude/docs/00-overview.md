# 00 — Overview: the method

This `.claude/docs/` directory does not describe an application domain: it describes
the **way of working** by which Claude Code collaborates on this project. It is the
heart of the framework — stack-agnostic — and it holds in every session, whatever
the project happens to build.

## The two pillars

1. **Persistent memory** (`.claude/memory/`) — Claude Code has no memory across
   sessions: we give it one, as files. `STATE.md` (the present), `TREE.md` (the
   map), `INDEX.md` (the route), plus the notes in `sessions/`, `components/`,
   `decisions/`, `plans/`. The memory is read at the start of a session and updated
   at the end of a task. *A task without updated memory is not done.*
   The memory is not an archive: it is what SHORTENS prompts. As long as a decision
   lives only in the chat, every later prompt has to repeat it; once it is on disk,
   the prompt POINTS at it ("run task N of the plan") and shrinks to a few lines.
   For the same reason expensive work (an assessment, a long review) is persisted
   IMMEDIATELY in a session note — BEFORE a `/clear` or a model switch, which lose
   the chat context.
2. **Process documentation** (`.claude/docs/`) — the permanent rules of HOW we work:
   planning, writing quality code, running the security review, using git, getting
   unstuck, improving the method itself.

## Selective loading

Load **only what the task at hand needs**, when it needs it — a token-efficiency choice
that now holds for the method itself:

- **Always**: the method's core, `.claude/rules/fw-core.md` — a rule with no `paths`, which
  Claude Code loads at every launch, again after a compaction and in a delegated
  general-purpose agent (measured on 2026-10-16; an Explore or a Plan agent skips
  `CLAUDE.md` and the rules with no `paths`, by Claude Code's docs) — and the project's
  `CLAUDE.md`. A delegated agent receives them as the main session last loaded them, at its
  launch or its last compaction: a change made since reaches it after the next one (seen at
  v4.0.0's gate). The core holds every rule that binds in every turn and a table of the
  moments at which each doc is read.
- **At the session's start**: `STATE.md`, through the SessionStart hook
  (`scripts/state-inject.sh`): at most 8,000 characters, its *Caution & open issues* first,
  and a line saying what was not shown when the file is longer. It is not imported.
- **At its moment**: a doc of this directory when the core's table names it, by section
  where the doc is long; a procedure when its `/fw:` command runs, the command reading its
  doc at its first step; a path-scoped rule of `.claude/rules/` when Claude reads or edits a
  file it matches.
- **Never**: an `@`-import of a method's file. Claude Code expands an import at launch, in a
  rule with `paths` too (measured on 2026-10-16), and a command's import at its invocation
  (measured once): the cost the loading above avoids. The framework's documentation check
  fails one in a method rule or command; in a project, `/fw:lint-memory` (check 13) lists
  every import with its cost.

The memory follows the same rule: the notes of only the components the task touches, the
session notes it points at, the files it reads besides. What a compaction drops — a file read
before it, a command's body past its first 5,000 tokens — is read again before the next step.

## The working cycle

```
  START OF SESSION                           END OF DELIVERABLE
        │                                             │
  read STATE.md ─▶ judge heaviness ─▶ execute ────────┤
  (SessionStart hook)  (heavy? → PLAN)   (per task)    │
        │                                             ▼
        │   END-OF-DELIVERABLE CYCLE (in order):
        │     1. /fw:security-review — only if under the gate
        │     2. /fw:retro           — reflect, record IMPs
        │     3. /fw:checkpoint      — align memory/docs with reality
        │     4. /fw:integrate       — merge+tag, then push: 2 blocks, human
        │
        └─ stuck? (2 attempts / a fork) ─▶ ESCALATION REPORT, then stop
```

1. **Plan** if the prompt is heavy → `01-task-planning.md`. No bureaucracy for small
   tasks. If the deliverable involves STRUCTURAL CHOICES, the plan is preceded by:
   a read-only assessment → a proposal with alternatives → the user's decision →
   recording it in `decisions/` (or an ADR) → the plan POINTS at the recorded
   decision instead of re-litigating it.
2. **Execute** while respecting quality → `02-code-quality.md`. Every task leaves the
   project in a consistent state and ends with a commit.
3. **Protect** sensitive components with the security gate → `03-security-gate.md`.
4. **Version** with discipline → `04-git-workflow.md`. Commits at logical
   checkpoints; push only on human confirmation.
5. **Get unstuck** without pushing on blindly → `05-escalation-protocol.md`.
6. **Improve the method** with the lessons you collect → `06-self-improvement.md`.
   Factual corrections are applied; rule changes are only PROPOSED.

## The end-of-deliverable cycle (the standard sequence)

A *deliverable* is a unit of work that goes to integration — a feature, a component, a
fix, a block of work —, whatever its size, and it is ALWAYS closed with this ordered
sequence: heaviness decides whether it gets a plan (`01-task-planning.md`), never whether
it closes with the cycle. A light deliverable has no plan and still closes with it;
`/fw:retro` is a no-op where there was no friction. The building blocks already exist in
the docs; what is fixed here is their ORDER, so that none of them is forgotten. The tasks
committed inside a deliverable, without an integration of their own, need only their
Definition of Done and their commit; a branch whose diff touches only the memory closes
lighter (*Scope and session hygiene*, below).

1. **Construction** — execution in atomic tasks, each with its Definition of Done
   green (`01-task-planning.md`, `02-code-quality.md`). It is the precondition of
   everything else: the deliverable builds and the tests pass. If you get stuck here,
   leave through the escalation (`/fw:sos`, `05-escalation-protocol.md`): it is not a
   step of the sequence, it is the way out.
2. **`/fw:security-review` — CONDITIONAL: only if the deliverable is under the gate.**
   Under the gate = sensitive — auth/authz, payments/money, personal data, the
   enforcement edge, surfaces that act on behalf of a client (the concrete list is
   the answer **Sensitive components** in `CLAUDE.md`, which `03-security-gate.md`
   points at) —, or a deliverable whose product asserts a security
   property (`03-security-gate.md`, *The lenses of the gate*). Under the gate this is a
   GATE: HIGH/CRITICAL findings are resolved BEFORE going on. Otherwise, skip it — and
   write the verdict anyway, one line with its reason, in the session note
   (`.claude/memory/sessions/README.md`, *Format*): a gate skipped and a gate forgotten
   must not look the same.
3. **`/fw:retro` — end-of-deliverable reflection (FIXED).** Was there friction? A
   rule or a doc that would have helped? → record the proposals as IMPs in
   `LEARNINGS.md` (`06-self-improvement.md`). It is lightweight: with no friction it
   is a no-op of a few seconds. The DECISIONS on the accumulated IMPs are taken in
   the periodic retrospective (`/fw:retro` again, but over the whole backlog). It goes
   BEFORE the checkpoint, so that the IMPs just recorded are persisted by the next
   commit.
4. **`/fw:checkpoint` — align memory and docs with the real state (FIXED).** Session
   note, `STATE.md`, `TREE.md`, `INDEX.md`, branch/merge reconciliation, commit
   (`04-git-workflow.md`). It does NOT push.
5. **`/fw:integrate` — merge + tag blocks, ready to paste (FIXED).** It computes the bump
   and the next version (`04-git-workflow.md`, *Versioning*) and emits the commands in
   two blocks: the local merge, the tag and the checks first, the push only after
   their output has been read. Push, merge and tag are performed by the HUMAN: it is
   the only step that leaves the agent's control.

> In short: FIXED steps 1·3·4·5; CONDITIONAL step 2 (`/fw:security-review`, only if
> under the gate). The order is not arbitrary — `/fw:retro` before `/fw:checkpoint` so that the
> checkpoint persists the IMPs just recorded; `/fw:integrate` last because it is the
> only one that touches shared state, and only once memory and docs are aligned. The
> merge it prints happens after the checkpoint, outside the session: the memory lags it
> by one step until the next deliverable, whose first `/fw:checkpoint` reconciles it — not a
> commit of its own after the merge, one more to push.

> **And `/fw:lint-memory`?** It is not a step of the end-of-deliverable cycle: it is a
> PERIODIC health-check. It is typically run together with the periodic retrospective
> over the IMP backlog (`/fw:retro` over the whole `LEARNINGS.md`), and in addition
> after events that touch many notes at once: big merges, restructurings of the
> memory, wide rewrites of `STATE.md`.

## Scope and session hygiene

- **One change at a time.** No "while we're at it": a cleanup discovered while
  working is pulled into its own task/branch ONLY if it has real impact (a bug);
  otherwise you note it down (memory or IMP) and stay inside the current scope.
- **`/clear` (or a new session) between UNRELATED deliverables.** The context of the
  previous deliverable contaminates the next one: close it with the
  end-of-deliverable cycle, then start clean. What you need afterwards is in the
  memory, not in the chat.
- **Unrelated work = unrelated branch.** Documentation or fixes foreign to the
  current feature branch go on a separate branch (or worktree), not appended to the
  branch you are working on. (Documentation RELATED to the change stays instead in
  the same commit/branch: rule 5 of the core, `.claude/rules/fw-core.md`.) A record made while no deliverable is
  open — an IMP, a harvest, the user's decisions on the backlog — is unrelated work too,
  whatever its size and in either branching model: it goes on a branch of its own, never
  onto the integration branch, and is integrated before the next deliverable's branch
  starts. A branch whose diff touches only `.claude/memory/` — the criterion is mechanical:
  every path `git diff --no-renames --name-only origin/<integration branch>...HEAD` lists
  starts there, the old path of a rename included — is exempt from the security gate and
  from `/fw:retro`: it closes with `/fw:checkpoint`, its note's gate line saying why, and is
  integrated with `/fw:integrate`'s no-tag blocks, the CI green where the project has one.
  With any other file, the full cycle; and in a project whose documentation is its product, a
  file of `.claude/memory/` that it ships is product, not memory (`04-git-workflow.md`,
  *Versioning*). Only the reconciliation of the previous merge rides on the next deliverable
  (*The end-of-deliverable cycle*, above).
- **Effort proportional to the consequences of being wrong.** "Expensive" reasoning
  (high model/effort) is reserved for where correctness has consequences: sensitive
  implementations, security reviews, adversarial analysis. For reading, structured
  writing over decisions already taken, and chores, the standard level is enough. It
  is a principle, not a rigid rule: tools change, proportionality does not.
- **Delegate with the user's words, and say what was not covered.** A brief for a
  delegated agent — a subagent, a workflow agent — quotes the user's decisions and
  constraints verbatim, or points at the record that holds them verbatim: a paraphrase
  drops what the agents then treat as undecided. One independent agent first; a fan-out —
  several agents, then verifiers — only where the consequences of being wrong warrant it,
  with a stall budget fixed before the run: past it the run is stopped, and what it did
  not cover is declared. A report built from several agents names its gaps — the agents
  that stalled or were skipped, the items left uncovered — and those items are checked by
  hand or reported as not covered.

## Process principles (in priority order)

1. **Security by default** — no secrets in plaintext (gitleaks hook), least
   privilege, mandatory review on sensitive components.
2. **Resilience** — work is split into committable units: an interruption never
   costs more than a single task.
3. **Traceability** — every non-obvious decision is written down (memory,
   decisions); the state is always reconstructible from `STATE.md`.
4. **Human control** — the agent proposes, the human disposes on whatever is
   irreversible or changes the rules: pushes, destructive operations, changes to its
   own rules.
5. **Self-improvement** — the method is not frozen: it improves with use, but in a
   controlled way and never through silent autonomy.

> The project's technology choices (language, framework, build, datastore, tests) do
> NOT live here: they live in `CLAUDE.md`, section *"Project-specific technical
> rules"*, and in the spots the setup marker marks.
