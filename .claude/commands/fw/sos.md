---
description: Escalation (docs/05) - produce the ESCALATION REPORT when stuck after 2 reasoned attempts or at a fork the docs do not cover, or carry out a pasted ARCHITECT RESPONSE
---
First Read `.claude/docs/05-escalation-protocol.md` whole; if the context has been compacted
since, read it again before the next step. Then, on: $ARGUMENTS
(if $ARGUMENTS is empty: on the session's current problem).

**If the user pasted an ARCHITECT RESPONSE block** (`===== ARCHITECT RESPONSE: ESC-<id> =====`):
carry it out per the doc's *HOW to handle the answer* — the ID against the open escalation,
the project's rules never suspended by the instructions, step by step with the outcome of
each, the session note updated with problem → cause → solution — and stop there.

**Otherwise produce RIGHT NOW an ESCALATION REPORT** in the doc's format. Mandatory
checklist before printing it:
1. Collect: branch and last commit (`git log -1 --oneline`), verbatim error,
   relevant excerpts of the files involved, relevant environment versions.
2. MASK every sensitive value (environment, token, password → `***`).
3. Fill in ALL the sections of the format — a report with empty sections is useless
   for someone who does not see this environment.
4. Print the report in a single, easily copyable code block.
5. Record the ID in the session note in memory.
6. Then STOP and wait for the ARCHITECT RESPONSE.
