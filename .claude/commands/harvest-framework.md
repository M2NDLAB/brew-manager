---
description: Harvests the IMPs marked "Destination: framework" and prints a copyable block to re-propose to the framework repo — it only reads and prints, never clone/copy/push/cross-repo
---
Harvest the lessons destined for the FRAMEWORK and prepare the block to carry upstream,
for: $ARGUMENTS (if $ARGUMENTS is empty: over the whole `LEARNINGS.md` backlog).

See the bridge in @.claude/docs/06-self-improvement.md (*"The bridge to the framework"*).
Complementary to `/retro`: `/retro` RECORDS the IMPs (and puts the marker
`Destination: framework` on them when the lesson is about the method);
`/harvest-framework` HARVESTS them to carry them upstream.

This command **only reads and prints**: it does NOT clone, it does NOT copy files between
repos, it does NOT run git/push towards the framework (the execution boundary —
`04-git-workflow.md` — and agnosticity: the project does not know, and must not know,
where the framework repo lives). The transfer and the re-registration as an IMP in the
framework remain HUMAN curation.

## 1. Context (the command is moot in the framework repo)
If you are running IN the framework repo itself (hybrid regime: every IMP is already a
lesson about the framework), there is nothing to tell apart nor to rake up: say so and
stop. The command serves the CLIENT projects, where `LEARNINGS.md` is the project backlog
and only SOME IMPs are framework-bound.

## 2. Harvest (read-only)
1. Find the marked entries:
   `grep -nE "Destination: framework|Destinazione: framework" .claude/memory/LEARNINGS.md`
   (by convention the marker is a single physical line). The Italian form is
   recognised as LEGACY: backlogs written before the release that introduced
   the English marker keep being raked up.
2. Define the perimeter:
   - default (`$ARGUMENTS` empty): ALL marked IMPs, in any section
     (OPEN / Applied / Deferred) — the whole backlog;
   - with `$ARGUMENTS`: narrow to the given criterion (a specific IMP `IMP-nnn`, a
     date/session, a section). Interpret `$ARGUMENTS` as a filter on the entries found.
3. For each entry in the perimeter, read the body of the IMP in `LEARNINGS.md` and collect:
   number and title, Origin, Observed problem, Proposal, Benefit/risk.

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
project.

```
===== FRAMEWORK HARVEST =====
# Re-propose each entry as an IMP in the framework repo (the number and the Origin's
# [[session note]] are assigned there).
# BEFORE pasting: check that NO names/paths/SHAs of this project are left.

### <title of the lesson>              (was IMP-<nnn> in this project)
- Origin: <generic and anonymous context>
- Observed problem: <...>
- Proposal: <what to change IN the framework: CLAUDE.md / docs/NN / command / hook / process>
- Expected benefit / risk: <...>

### <title of the next lesson>         (was IMP-<nnn> in this project)
- ...
===== END OF HARVEST =====
```

## 5. Close
- Recall that the next step is HUMAN: open the framework repo and register the
  entries as IMP proposals, one by one, according to the framework's rules, after
  re-checking the anonymisation.
- Do NOT mark anything as "already carried upstream" and do NOT modify `LEARNINGS.md`: the
  command does not mutate state. De-duplication between successive harvests is human
  curation — to avoid raking up again the lessons already carried upstream, narrow with
  `$ARGUMENTS` (e.g. to a date) or annotate by hand the entries already carried upstream.
- Then STOP.
