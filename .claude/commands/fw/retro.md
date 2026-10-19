---
description: Retrospective - reflect on the deliverable, or on the whole IMP backlog, and record IMP proposals (docs/06). Use at the end of every deliverable, before /fw:checkpoint, or periodically
---
Run an improvement retrospective according to `.claude/docs/06-self-improvement.md` on:
$ARGUMENTS (if $ARGUMENTS is empty: on the latest sessions recorded in memory).

First Read `.claude/docs/06-self-improvement.md` whole, and the section *The
end-of-deliverable cycle (the standard sequence)* of `.claude/docs/00-overview.md` —
`grep -n '^## '` gives its line —; if the context has been compacted since, read them again
before the next step.

Two intensities of use (the cycle in `docs/00`):
- **At the end of a deliverable** (fixed step of the cycle, BEFORE `/fw:checkpoint`):
  LIGHT reflection — run steps 1-3 and RECORD any IMPs; without friction it is a no-op
  of a few seconds. The decisions (steps 4-6) can be deferred.
- **Periodic / on-demand**: FULL review of the accumulated backlog — all the steps,
  with the user's decisions on the open IMPs.

1. Read .claude/memory/LEARNINGS.md by section — `grep -n '^## \|^### '` gives its
   sections and entries: the OPEN section and the entries the recent notes cite at the end
   of a deliverable, each section in turn at a periodic retrospective; a single Read stops
   at 25,000 tokens, and a long backlog is larger. Then the recent session notes in
   .claude/memory/sessions/.
2. Look for patterns: repeated errors, resolved escalations whose lessons have not yet
   become proposals, process friction, docs re-read/misunderstood, systemic security
   review findings.
3. For every pattern found: create or update an IMP-nnn proposal in the backlog
   (observed problem → concrete proposal → benefit/risk).
4. Present the OPEN proposals to the user in a table:
   ID | Problem | Proposal | Estimated impact | Recommended yes/no and why.
5. WAIT for the user's decision on each one: approve / reject / defer.
6. Apply the approved ones (a dedicated commit for each), move the rejected ones to
   "Rejected" with the reason and the deferred ones to "Deferred" with the resumption
   trigger.

Do NOT change rules or config without explicit approval — only the Level 1 factual
corrections are auto-applicable.
