---
description: Retrospective - review the learnings and propose process improvements
---
Run an improvement retrospective according to
@.claude/docs/06-self-improvement.md on: $ARGUMENTS
(if $ARGUMENTS is empty: on the latest sessions recorded in memory).

Two intensities of use (see the cycle in @.claude/docs/00-overview.md):
- **At the end of a deliverable** (fixed step of the cycle, BEFORE `/checkpoint`):
  LIGHT reflection — run steps 1-3 and RECORD any IMPs; without friction it is a no-op
  of a few seconds. The decisions (steps 4-6) can be deferred.
- **Periodic / on-demand**: FULL review of the accumulated backlog — all the steps,
  with the user's decisions on the open IMPs.

1. Read .claude/memory/LEARNINGS.md and the recent session notes in
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
