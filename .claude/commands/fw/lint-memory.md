---
description: Health-check of the memory (docs/06) - contradictions, stale state, orphans, broken links, STATE.md's budget, the rules' globs and imports. Use periodically, with the periodic retro, or after big merges or memory rewrites
---
Run a LINT of the persistent memory (`.claude/memory/`) and of the process
pointers: a health-check of the CONSISTENCY of the knowledge base, on: $ARGUMENTS
(if empty: on the whole memory).

This is NOT a process retrospective (`/fw:retro`, `docs/06`, *What this protocol is NOT*):
the retro proposes WHAT TO IMPROVE in the workflow; the lint verifies the HEALTH of the DATA.
Read the notes and `LEARNINGS.md` by section (`grep -n '^## \|^### '`): a single Read stops
at 25,000 tokens. If the context has been compacted during the lint, re-read the checks
below before the next one.
**When to run it** (the cycle in `docs/00`): NOT at every
deliverable — periodically, normally together with the periodic retrospective on the
IMP backlog, and after events that touch many notes at once (big merges,
restructurings of the memory, wide rewrites of `STATE.md`).
**Resolution criterion**: this is a framework for software — a contradiction
is a BUG, not a tension to preserve. The lint FLAGS and PROPOSES the correction,
always aligning the state to reality (never the other way round — unless reality violates
a rule: then it is a process bug, not a memory bug, and it goes to escalation/IMP).

## Checks
1. **State vs reality.** Is `STATE.md` (progress, "Active branches", "What exists")
   aligned with git? Verify with `git branch`, `git branch --merged <integration>`,
   `git log --oneline -10`: branches given as existing but already merged/deleted,
   features "in progress" that turn out to be already committed, a stale "last".
2. **Contradictions between notes.** Decisions (`decisions/`), component notes
   (`components/`) and session notes (`sessions/`) that contradict each other or
   `STATE.md`.
3. **Stale claims.** Statements made obsolete by more recent facts (a decision
   superseded by a later one without the first being marked as such).
4. **Orphan pages.** Notes with no incoming reference (not cited by `INDEX.md`
   nor by a `[[wikilink]]` from other notes): either they are to be linked, or they are dead.
5. **Concepts without a page.** Concepts/components cited repeatedly in the notes but
   lacking a page of their own — candidates for a dedicated note.
6. **Missing cross-references.** Clearly related notes not linked by a
   `[[wikilink]]`; `INDEX.md` not listing notes that actually exist.
7. **Broken links.** `[[wikilink]]` pointing at non-existent notes.
8. **Consistency of `TREE.md`.** Aligned with the real structure of the filesystem
   (regenerable as per `/fw:checkpoint`).
9. **`LEARNINGS` ↔ `STATE` consistency.** The recorded items are aligned between the
   files: a deferred IMP whose trigger is near or blocking also appears among the
   open issues of `STATE.md` (and vice versa); the debt accepted by the security
   gate (docs/03) lives in `STATE.md` with its reason; every debt entry has its
   explicit TRIGGER, it is not generic.
10. **Grep-visible setup markers.** No *slot* to be filled in is broken by word-wrap
    across two physical lines: it would escape the grep with which the framework's setup
    and upgrade find the slots (the framework's `SETUP.md`, §2), silently staying unfilled.
    Sentinel: `grep -rnE "TO BE DEFINED AT$|DA DEFINIRE AL$" .` — every hit is a
    candidate. The Italian form is recognised as LEGACY: projects grafted
    before the release that introduced the English marker do not break. KNOWN false positives to ignore (prose that *discusses* the
    marker, not a slot): the guidance box of the framework's `SETUP.md`, where a copy is
    kept, and the IMP records of `LEARNINGS.md`. A hit elsewhere, or one that really is a
    fillable slot, must be recompacted onto a single physical line.
11. **Inventories vs reality.** Do the inventory-lists ENUMERATED below correspond
    to the filesystem? Set comparison in BOTH directions: an entry that EXISTS but is missing
    from the inventory; an entry LISTED but non-existent. ONLY the enumerated
    lists are checked — never the prose mentions elsewhere (it is the enumeration that avoids
    list-vs-prose false positives):
    (a) files in `.claude/commands/fw/`, each the command `/fw:<name>` ↔ the *Quick
        commands* list of the core, `.claude/rules/fw-core.md`, and, where present, the
        `commands/` line of the "Structure" of `README.md`;
    (b) PROCESS targets of the `Makefile` ↔ the same lists. Process ones = the
        recipe invokes a script from `scripts/` (STRUCTURAL anchoring, not
        positional: it holds even when the setup fills in or removes the
        setup marker's banner); `help` is excluded (a meta-target that prints the
        list) and the PROJECT targets (build/test/run of the stack) are OUT OF
        scope — never flag them;
    (c) files in `scripts/` ↔ the table of `scripts/README.md`.
    An entry counts also in an equivalent form (`make reset-task` ≡
    `./scripts/reset-task.sh`). A mismatch = BUG (lint semantics): the doc is aligned
    to reality. Excluded by declaration, as in check 10 (they record PAST
    states, not inventories of the current state): the append-only documents (a
    `CHANGELOG.md`, if the project keeps one) and the IMP records of `LEARNINGS.md`.
    In client projects only the files copied from the template count (the `README.md`
    of the framework is not among them).
12. **`STATE.md` within its budget, its open issues first.** The SessionStart hook shows
    8,000 characters of it, *Caution & open issues* first (`scripts/state-inject.sh`):
    `wc -m .claude/memory/STATE.md` gives its size, and `r="$(git rev-parse
    --show-toplevel)" && bash "$r/scripts/state-inject.sh" "$r/.claude/memory/STATE.md"`
    what the hook prints: its first line the banner, its second `## Caution & open issues`
    or the line saying the file has none — any other output is a measurement that failed:
    report it, never as within the budget —, and a line opening with `=== STATE.md: ` says
    how many characters were not shown — comments not counted, so not `wc -m`'s number.
    Over the budget is a finding: propose the reduction `/fw:checkpoint` describes — the
    history to the session notes, each open issue one line with its trigger and a pointer —
    and apply it only with the user's confirmation, since it rewrites the dashboard; on a
    framework upgrade's branch, before its merge, report the size and propose nothing — the
    first `/fw:checkpoint` after the merge condenses it, never the upgrade. A `STATE.md` with
    no section titled exactly `## Caution & open issues` is a finding too: its open issues
    reach no session first — the hook says so in one line —; propose the title, or moving
    the entries that belong there under it.
13. **The rules' globs and the imports.** (a) Each glob of the `paths` of the rules in
    `.claude/rules/` matches at least one tracked file (`git ls-files` against the glob): a
    glob that matches nothing is a rule that never loads; `fw-code-quality.md`'s still
    holding the setup marker is a slot to answer (the framework's `SETUP.md`, §2). (b) Every
    `@path` outside a code span in `CLAUDE.md`, in `.claude/rules/` and in
    `.claude/commands/` loads its file — at every launch from `CLAUDE.md` and from any rule,
    path-scoped or not, at its invocation from a command (measured once): list each with its file's size,
    the cost it adds; one in a method file (`fw-*`, `fw/`) is a bug — the method's files
    have their docs Read instead.

## Output and resolution
A table: **Area | Problem found | Type** (misalignment / contradiction /
orphan / broken link / stale claim) **| Proposed correction**.

- **Mechanical, low-risk corrections** (regenerating `TREE.md`, reconciling
  "Active branches" with git, adding a missing `[[wikilink]]`, fixing a broken
  link): APPLY them and say so.
- **Cases that require judgement** (which of two contradictory notes is the right
  one, which claim is the true one): PROPOSE and ask for confirmation, do not guess.

If a misalignment reveals a PROCESS hole (not just a data one), record it as an
IMP in `LEARNINGS.md` (docs/06): it is the only bridge between the lint and the retrospective.
