# 06 — Continuous self-improvement (configuration and process)

The project improves itself: not only the code, but the **working configuration**
(docs, rules, commands, memory). This protocol defines HOW, with a sharp boundary
between what Claude Code fixes on its own and what it only PROPOSES.

## The backlog: `.claude/memory/LEARNINGS.md`

It is the register of improvement proposals (IMP-nnn). Numbering starts at 001. The
format is documented in the file itself (sections: OPEN / Applied / Deferred /
Rejected).

## LEVEL 1 — Factual corrections: apply directly

When the documentation is in DEMONSTRABLE DISAGREEMENT with the reality of the code
or the environment (a command that no longer exists, a moved path, a wrong version, a
changed name):
1. Align the doc with reality (never the other way round — unless reality violates a
   rule, and then it is a bug, not a doc correction).
2. Note the correction in the session note.
3. Include it in the current task's commit (scope: `docs`).

There is no judgement here: there is only synchronisation. A doc that lies is worse
than a doc that is missing.

> **Scope of LEVEL 1.** It concerns the documentation of the METHOD and of the
> project MANAGED with this framework. During a GRAFT onto an existing project
> (brownfield), the host's pre-existing
> documentation that disagrees with reality is NOT corrected as a matter of course:
> it is recorded in `STATE.md` ("Documentation debt") and corrected only as a task
> decided by the user — the scope hygiene of `00-overview.md` prevails (one change at
> a time). Once the graft is COMPLETE the host's documentation IS the documentation
> of the managed project and falls under LEVEL 1; only the debts already recorded in
> `STATE.md` during the graft stay outside, and they are worked off as tasks decided
> by the user.

## LEVEL 2 — Rule and process improvements: only PROPOSE

When you observe: recurring friction (the same question/error across several
sessions), a rule that is ambiguous or in conflict with another, a process step that
wastes time without benefit, a missing convention that would have prevented a bug,
the opportunity for a new slash command or hook:
1. Do NOT modify `CLAUDE.md`, the rules in the docs, the commands or `settings.json`.
2. Record an IMP-nnn proposal in `LEARNINGS.md` (problem → proposal → benefit).
3. If it is urgent or blocking: flag it to the user at the end of the task; otherwise
   it stays in the backlog for the retrospective (`/retro`).

The reason for the constraint: the rules are the contract with the user. A system
that rewrites its own rules drifts, and after N sessions nobody knows any more which
configuration is in force, or why. **The agent proposes, the human disposes.**

## When to LOOK for improvements (triggers)

- You got something wrong that a rule/doc could have prevented → IMP.
- You re-read the same thing three times to understand it → the doc can be improved →
  IMP.
- An escalation (`ESC-...`) was resolved → the lesson goes into `LEARNINGS.md` on top
  of the session note: escalations are the best source of improvements.
- A security review (`/security-review`) found something systemic → IMP.
- **At the end of a deliverable, the `/retro` step** (the cycle in `00-overview.md`):
  30 seconds of reflection — was there friction? a rule/doc that would have helped? →
  record the IMP. It goes BEFORE `/checkpoint`, which then persists it in the commit.

## Applying approved proposals

When the user approves an IMP (directly or through an escalation answer):
1. Apply the change in the right file (`CLAUDE.md` / doc / command / config).
2. Move the IMP into "Applied" with the date and the commit sha.
3. A dedicated commit: `chore(claude): apply IMP-nnn — <title>`.
4. If the change alters a numbered rule of `CLAUDE.md`: check that the other rules
   and the docs stay coherent (no orphan references).

## The bridge to the framework — "framework-bound" lessons

So far every IMP is treated as a lesson about THIS project. But when the project USES
the framework (rather than IS the framework), some of the lessons are not about the
project: they are about the METHOD — an ambiguous rule, a missing command, a process
step that creates friction everywhere, not only here. Those lessons have a second
destination, the framework repo, so that they improve the NEXT project that uses it
too: it is the "loop" that makes the framework evolve from the projects it is grafted
onto.

**How it is marked.** An IMP that concerns the framework carries, in its body in
`LEARNINGS.md`, the line `- Destination: framework` (see the IMP format in the header
of `LEARNINGS.md`). It is a DESTINATION attribute, not a third level: the lesson stays
a Level 2 one (it is PROPOSED, not applied autonomously) and follows its normal cycle
IN the project; the marker only adds "this one, besides here, must be sent upstream".
The criterion for marking it: it is useful to ANY project using the framework, not
only to this one. A single physical line, so that `/harvest-framework` collects it via
grep.

**How it goes upstream — `/harvest-framework`.** The command collects from the backlog
the IMPs marked `Destination: framework` and PRINTS a copyable block for them (problem
→ proposal → benefit), ready to be re-proposed as an IMP in the framework repo. The
command **only reads and prints**: it does not clone, does not copy files between
repos, does not run git/push towards the framework. The transfer is **human
curation**: whoever runs it pastes the block, **anonymises** it (no name of this
project/client/environment in the framework's shared history —
`04-git-workflow.md`) and records it as a new proposal in the framework, where it will
be assessed like any other contribution, according to its own rules.

**Why this boundary.** A command that actually wrote into the framework repo would
violate two rules at once: the execution boundary — shared history is moved by the
human, not by the agent (`04-git-workflow.md`) — and agnosticism: the template knows
nothing, and must know nothing, about the concrete instance using it (it does not know
where the framework repo lives relative to the project). The copyable block is
deliberately the only output: it makes the transfer explicit, reviewable and under
human control.

> In the FRAMEWORK REPO itself the attribute is moot: here every IMP is already a
> lesson about the framework (declared hybrid regime), so nothing is marked and
> `/harvest-framework` has no material to rake in. The command is for client projects.

## What this protocol is NOT

- It is not continuous refactoring of the application code (that follows
  `02-code-quality.md` and happens inside tasks, not on the sly).
- It is not a licence to add tools/dependencies "because they improve things" — those
  go through recording a decision.
- It is not verbose self-assessment on every message: it is ONE moment of reflection
  at the end of a deliverable (the `/retro` step) + recording whenever friction shows
  up.
- It is not the memory lint. The coherence of the knowledge base (state misaligned
  with reality, contradictory notes, orphan pages, broken links) is a separate
  health-check — `/lint-memory` — where a contradiction is a BUG to be FIXED, not an
  improvement to be proposed. The retro looks at the PROCESS, the lint at the health
  of the DATA; the bridge between the two is the IMP the lint opens when a
  misalignment reveals a process gap.
