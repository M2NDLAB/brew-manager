---
description: Produce an Escalation Report for an external expert interlocutor
---
Produce RIGHT NOW an ESCALATION REPORT following the format defined in
@.claude/docs/05-escalation-protocol.md about: $ARGUMENTS
(if $ARGUMENTS is empty: about the session's current problem).

Mandatory checklist before printing the report:
1. Collect: branch and last commit (`git log -1 --oneline`), verbatim error,
   relevant excerpts of the files involved, relevant environment versions.
2. MASK every sensitive value (environment, token, password → `***`).
3. Fill in ALL the sections of the format — a report with empty sections is useless
   for someone who does not see this environment.
4. Print the report in a single, easily copyable code block.
5. Record the ID in the session note in memory.
6. Then STOP and wait for the ARCHITECT RESPONSE.
