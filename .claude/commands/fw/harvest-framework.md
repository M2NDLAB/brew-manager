---
description: Harvests the IMPs marked "Destination: framework" into a copyable block for the framework repo - it only reads and prints (docs/06). Use when the user wants the project's lessons sent upstream
---
Harvest the lessons destined for the FRAMEWORK and prepare the block to carry upstream,
for: $ARGUMENTS (if $ARGUMENTS is empty: over the whole `LEARNINGS.md` backlog).

First Read the section *The bridge to the framework* of
`.claude/docs/06-self-improvement.md` — `grep -n '^## '` gives its line, read from its title
to the next —; if the context has been compacted since, read it again before the next step.
Complementary to `/fw:retro`: `/fw:retro` RECORDS the IMPs (and puts the marker
`Destination: framework` on them when the lesson is about the method);
`/fw:harvest-framework` HARVESTS them to carry them upstream.

This command **only reads and prints**: it does NOT clone, it does NOT copy files between
repos, it does NOT run git/push towards the framework (the execution boundary of
`docs/04`: shared history is moved by the human, never by the agent; and agnosticism —
the project does not know, and must not know, where the framework repo lives). The
transfer and the re-registration as an IMP in the framework remain HUMAN curation.

## 1. Context
The command serves a project that USES the framework, where `LEARNINGS.md` is the
project's backlog and only SOME IMPs are framework-bound: those are the ones it harvests.

## 2. Harvest (read-only)
1. Find the marked entries:
   `grep -nE "^- Destination: framework|^- Destinazione: framework" .claude/memory/LEARNINGS.md`
   (by convention the marker is a single physical line, so a mention in prose is not
   a hit). The Italian form is recognised as LEGACY: backlogs written before the
   release that introduced the English marker keep being raked up. Only a hit inside
   an entry (`### IMP-…`) counts: the format comment of `LEARNINGS.md` shows the
   marker without being an entry.
2. Define the perimeter:
   - default (`$ARGUMENTS` empty): ALL marked IMPs, in any section
     (OPEN / Applied / Deferred / Rejected) — the whole backlog;
   - with `$ARGUMENTS`: narrow to the given criterion (a specific IMP `IMP-nnn`, a
     date/session, a section). Interpret `$ARGUMENTS` as a filter on the entries found.
3. For each entry in the perimeter, read the body of the IMP in `LEARNINGS.md` and collect:
   number and title, Origin, Observed problem, Proposal, Benefit/risk — and the date of the
   session note its Origin cites: the date at the start of the note's name, never the name
   itself, whose slug can name the project; the first note's when it cites several, the
   entry's own Date when it cites none. The number and that date let the framework count the
   lesson once.

## 3. Anti-vacuity (mandatory)
If NO IMP is marked `Destination: framework` in the chosen perimeter: do NOT print an
empty block. State explicitly that there is no framework-bound material, recall how
a lesson is marked (the line `- Destination: framework` in the body of the IMP, see the
format in `LEARNINGS.md`) and stop. A silent empty output would look like "everything
harvested" when it is not.

## 4. Print the FRAMEWORK HARVEST block
A single copyable code block. For each lesson use the format of a framework IMP proposal
(so it is ready to paste into its `LEARNINGS.md`), BUT with the local references
ANONYMISED: no name of this project/client/environment, no project-specific
path, no local SHA, no `[[wikilink]]` to a local session note (docs/04: the shared
history of the framework is agnostic). Rephrase "Origin" in generic terms ("emerged
while working on a project that uses the framework"), never with the identity of the
project. The entry's number and its source note's date stay, still anonymous.

```
===== FRAMEWORK HARVEST =====
# Re-propose each entry as an IMP in the framework repo (the number and the Origin's
# [[session note]] are assigned there) — or, when the framework already holds it (the
# same entry and date), as evidence on that entry.
# BEFORE pasting: check that NO names/paths/SHAs of this project are left.

### <title of the lesson>              (was IMP-<nnn> in this project, <YYYY-MM-DD>)
- Origin: <generic and anonymous context>
- Observed problem: <...>
- Proposal: <what to change IN the framework: the core / docs/NN / command / hook / process>
- Expected benefit / risk: <...>

### <title of the next lesson>         (was IMP-<nnn> in this project, <YYYY-MM-DD>)
- ...
===== END OF HARVEST =====
```

## 5. Close
- Recall that the next step is HUMAN: open the framework repo and register each entry —
  a new proposal, or evidence on the one it repeats (the framework's `CONTRIBUTING.md`) —,
  one by one, after re-checking the anonymisation.
- Do NOT mark anything as "already carried upstream" and do NOT modify `LEARNINGS.md`: the
  command does not mutate state. A lesson harvested twice is counted once by the
  framework, at recording time, from its number and date; to print less, narrow with
  `$ARGUMENTS` (e.g. to a date).
- Then STOP.
