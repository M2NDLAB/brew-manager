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

Load **only the files relevant to the task at hand**, not everything at once: it is
a token-efficiency choice. `CLAUDE.md` is the index; from there you pull in what you
need. The same logic applies to the memory: you load the notes of only the
components the task touches.

## The working cycle

```
  START OF SESSION                           END OF DELIVERABLE
        │                                             │
  read STATE.md ─▶ judge heaviness ─▶ execute ────────┤
  (SessionStart hook)  (heavy? → PLAN)   (per task)    │
        │                                             ▼
        │   END-OF-DELIVERABLE CYCLE (in order):
        │     1. /security-review — only if sensitive (gate)
        │     2. /retro           — reflect, record IMPs
        │     3. /checkpoint      — align memory/docs with reality
        │     4. /integrate       — merge+tag block, push = human
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

A *deliverable* (a complete heavy unit: a feature, a component, a block of work) is
ALWAYS closed with this ordered sequence. The building blocks already exist in the
docs; what is fixed here is their ORDER, so that none of them is forgotten. Small,
isolated tasks do not need the full ritual (see `01-task-planning.md`): the
Definition of Done and the commit are enough.

1. **Construction** — execution in atomic tasks, each with its Definition of Done
   green (`01-task-planning.md`, `02-code-quality.md`). It is the precondition of
   everything else: the deliverable builds and the tests pass. If you get stuck here,
   leave through the escalation (`/sos`, `05-escalation-protocol.md`): it is not a
   step of the sequence, it is the way out.
2. **`/security-review` — CONDITIONAL: only if the deliverable is sensitive.**
   Sensitive = auth/authz, payments/money, personal data, the enforcement edge,
   surfaces that act on behalf of a client (`03-security-gate.md`; the concrete list
   for brew-manager is in `03-security-gate.md` and in CLAUDE.md, rule 8:
   mod_00, mod_05, mod_bk, mod_las, brew_manager.sh, lib/common.sh). If it is
   sensitive this is a GATE: HIGH/CRITICAL findings are resolved BEFORE going on.
   If it is not sensitive, skip it.
3. **`/retro` — end-of-deliverable reflection (FIXED).** Was there friction? A
   rule or a doc that would have helped? → record the proposals as IMPs in
   `LEARNINGS.md` (`06-self-improvement.md`). It is lightweight: with no friction it
   is a no-op of a few seconds. The DECISIONS on the accumulated IMPs are taken in
   the periodic retrospective (`/retro` again, but over the whole backlog). It goes
   BEFORE the checkpoint, so that the IMPs just recorded are persisted by the next
   commit.
4. **`/checkpoint` — align memory and docs with the real state (FIXED).** Session
   note, `STATE.md`, `TREE.md`, `INDEX.md`, branch/merge reconciliation, commit
   (`04-git-workflow.md`). It does NOT push.
5. **`/integrate` — merge + tag block, ready to paste (FIXED).** It computes the bump
   and the next version (`04-git-workflow.md`, *Versioning*) and emits the commands.
   Push, merge and tag are performed by the HUMAN: it is the only step that leaves
   the agent's control.

> In short: FIXED steps 1·3·4·5; CONDITIONAL step 2 (`/security-review`, only if
> sensitive). The order is not arbitrary — `/retro` before `/checkpoint` so that the
> checkpoint persists the IMPs just recorded; `/integrate` last because it is the
> only one that touches shared state, and only once memory and docs are aligned.

> **And `/lint-memory`?** It is not a step of the end-of-deliverable cycle: it is a
> PERIODIC health-check. It is typically run together with the periodic retrospective
> over the IMP backlog (`/retro` over the whole `LEARNINGS.md`), and in addition
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
  the same commit/branch: rule 5 of `CLAUDE.md`.)
- **Effort proportional to the consequences of being wrong.** "Expensive" reasoning
  (high model/effort) is reserved for where correctness has consequences: sensitive
  implementations, security reviews, adversarial analysis. For reading, structured
  writing over decisions already taken, and chores, the standard level is enough. It
  is a principle, not a rigid rule: tools change, proportionality does not.

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
> NOT live here: they live in `CLAUDE.md`, section
> *"Project-specific technical rules"* (filled in at the framework graft, 2026-07-12).
